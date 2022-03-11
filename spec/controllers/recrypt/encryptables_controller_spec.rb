# frozen_string_literal: true

require 'spec_helper'

describe Recrypt::EncryptablesController do
  include ControllerHelpers

  context 'GET new' do
    it 'starts new successful encryptables recrypt for user Teams' do
      login_as(:alice)
      team1 = teams(:team1)
      encryptable1 = team1.folders.first.encryptables.first

      get :new

      team1.reload
      encryptable1.reload

      expect(response).to have_http_status 302
      expect(response).to redirect_to 'http://test.host/dashboard'
      expect(team1.encryption_algorithm).to eq('AES256IV')
      expect(team1.recrypt_state).to eq('done')
      expect(encryptable1.encryption_algorithm).to eq('AES256IV')
    end

    it 'starts new unsuccessful encryptables recrypt for user Teams' do
      login_as(:alice)
      team1 = teams(:team1)

      credential1 = Encryptable::Credentials.new(folder: team1.folders.first)
      credential1.save(validate: false)

      allow_any_instance_of(Team).to receive(:encryption_algorithm).and_return('AES256')

      get :new

      team1.reload

      expect(response).to have_http_status 302
      expect(team1.encryption_algorithm).to eq('AES256')
      expect(team1.recrypt_state).to eq('failed')
      expect(team1.encryption_algorithm).to eq('AES256')
    end

    it 'skips encryptables recrypt for user Teams if not needed' do
      login_as(:alice)
      team1 = teams(:team1)

      credential1 = Encryptable::Credentials.new(folder: team1.folders.first)
      credential1.save(validate: false)

      allow_any_instance_of(Team).to receive(:encryption_algorithm).and_return('AES256IV')

      get :new

      team1.reload

      expect(response).to have_http_status 302
      expect(team1.encryption_algorithm).to eq('AES256IV')
      expect(team1.recrypt_state).to eq('failed')
      expect(team1.encryption_algorithm).to eq('AES256IV')
    end

    it 'resets team password within encryptables recrypt' do
      login_as(:alice)
      alice = users(:alice)
      bob = users(:bob)
      team1 = teams(:team1)
      team_password = team1.decrypt_team_password(alice, alice.decrypt_private_key('password'))

      get :new

      team1.reload
      new_team_password_alice = team1.decrypt_team_password(alice,
                                                            alice.decrypt_private_key('password'))
      new_team_password_bob = team1.decrypt_team_password(bob,
                                                          bob.decrypt_private_key('password'))

      expect(response).to have_http_status 302
      expect(team_password).not_to eq(new_team_password_alice)
      expect(team1.encryption_algorithm).to eq('AES256IV')

      credentials = team1.folders.first.encryptables.first
      credentials.decrypt(new_team_password_bob)
      expect(credentials.cleartext_username).to eq('test')
      expect(credentials.cleartext_password).to eq('password')
    end

    it 'recrypts ose secret encryptable' do
      login_as(:alice)
      alice = users(:alice)
      team1 = teams(:team1)
      team_password = team1.decrypt_team_password(alice, alice.decrypt_private_key('password'))
      ose_secret = create_ose_secret(team_password)

      get :new

      team1.reload
      ose_secret.reload
      team_password = team1.decrypt_team_password(alice, alice.decrypt_private_key('password'))

      expect(response).to have_http_status 302
      expect(response).to redirect_to 'http://test.host/dashboard'

      ose_secret.decrypt(team_password)
      expect(ose_secret.encryption_algorithm).to eq('AES256IV')
      expect(ose_secret.cleartext_ose_secret).to eq(cleartext_ose_secret)
    end
  end

  private

  def create_ose_secret(team_password)
    secret = Encryptable::OSESecret.new(name: 'ose_secret',
                                        folder: folders(:folder1))

    secret.cleartext_ose_secret = cleartext_ose_secret
    secret.encrypt(team_password)
    secret.save!
    secret
  end

  def cleartext_ose_secret
    Base64.strict_decode64(FixturesHelper.read_encryptable_file('example_secret.secret'))
  end

end
