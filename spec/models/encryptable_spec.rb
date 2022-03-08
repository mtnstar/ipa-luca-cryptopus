# frozen_string_literal: true

require 'spec_helper'

describe Encryptable do

  let(:bob) { users(:bob) }
  let(:bobs_private_key) { bob.decrypt_private_key('password') }
  let(:encryptable) { encryptables(:credentials1) }
  let(:team) { teams(:team1) }
  let(:team_password) {
    "K\xFDp\x80Q\v\x1AH\x84\x80\xFC\x8D\xBB\xCB\xA3" +
    "\x8F\x8A\xFE\x92c\\\x93\x87\xA9\x129\xD4t\x11\xFD\xF7\x9E"
  }

  it 'does not create second credential in same folder' do
    params = {}
    params[:name] = 'Personal Mailbox'
    params[:folder_id] = folders(:folder1).id
    params[:type] = 'Encryptable::Credentials'
    credential = Encryptable::Credentials.new(params)
    expect(credential).to_not be_valid
    expect(credential.errors.keys).to eq([:name])
  end

  it 'creates second entryptable with credentials' do
    params = {}
    params[:name] = 'Shopping Account'
    params[:folder_id] = folders(:folder2).id
    params[:type] = 'Encryptable::Credentials'
    credential = Encryptable::Credentials.new(params)
    expect(credential).to be_valid
  end

  it 'decrypts username and password' do
    team_password = team.decrypt_team_password(bob, bobs_private_key)

    encryptable.decrypt(team_password)

    expect(encryptable.cleartext_username).to eq('test')
    expect(encryptable.cleartext_password).to eq('password')
  end

  it 'updates password and username' do
    team_password = team.decrypt_team_password(bob, bobs_private_key)

    encryptable.cleartext_username = 'new'
    encryptable.cleartext_password = 'foo'

    encryptable.encrypt(team_password)
    encryptable.save!
    encryptable.reload
    encryptable.decrypt(team_password)

    expect(encryptable.cleartext_username).to eq('new')
    expect(encryptable.cleartext_password).to eq('foo')
  end

  it 'does not create credential if name is empty' do
    params = {}
    params[:name] = ''
    params[:description] = 'foo foo'
    params[:folder_id] = folders(:folder1).id
    params[:type] = 'Encryptable::Credentials'

    credential = Encryptable::Credentials.new(params)

    credential.encrypted_data[:password] = { data: 'foo', iv: nil }
    credential.encrypted_data[:username] = { data: 'foo', iv: nil }

    expect(credential).to_not be_valid
    expect(credential.errors.full_messages.first).to match(/Name/)
  end

  it 'sets team encryption algorithm as encryption algorithm' do
    params = {}
    params[:name] = ''
    params[:description] = 'foo foo'
    params[:type] = 'Encryptable::Credentials'
    params[:folder_id] = folders(:folder1).id
    params[:encryption_algorithm] = 'DES'

    credential = Encryptable::Credentials.new(params)

    expect(credential.encryption_algorithm).to eq('AES256')
  end

  it 'sets previous team encryption algorithm as encryption algorithm' do
    team = Team.create!(name: 'Puzzle Members')
    folder = Folder.create!(name: 'Accounts', team: team)

    params = {}
    params[:name] = ''
    params[:description] = 'foo foo'
    params[:type] = 'Encryptable::Credentials'
    params[:folder_id] = folder.id
    params[:encryption_algorithm] = 'DES'

    allow(folder).to receive_message_chain(:team, :encryption_algorithm).and_return('AES256')

    credential = Encryptable::Credentials.new(params)
    expect(credential.encryption_algorithm).to eq('AES256IV')
  end

  it 'uses aes256iv algorithm for encryption and decryption' do
    params = {}
    params[:name] = 'Cryptopus Account'
    params[:description] = 'foo foo'
    params[:type] = 'Encryptable::Credentials'
    params[:folder_id] = folders(:folder1).id

    allow_any_instance_of(Encryptable::Credentials).to receive(:encryption_algorithm).and_return('AES256IV')

    credential = Encryptable::Credentials.new(params)
    credential.cleartext_password = 'password'
    credential.cleartext_username = 'alice'

    credential.encrypt(team_password)

    credential.save!

    credential = Encryptable::Credentials.find(credential.id)
    credential.decrypt(team_password)

    expect(credential.encryption_algorithm).to eq('AES256IV')
    expect(credential.cleartext_password).to eq('password')
    expect(credential.cleartext_username).to eq('alice')
  end

  it 'uses aes256 algorithm for encryption and decryption' do
    params = {}
    params[:name] = 'Cryptopus Account'
    params[:description] = 'foo foo'
    params[:type] = 'Encryptable::Credentials'
    params[:folder_id] = folders(:folder1).id

    allow_any_instance_of(Encryptable::Credentials).to receive(:encryption_algorithm).and_return('AES256')

    credential = Encryptable::Credentials.new(params)

    credential.cleartext_password = 'password'
    credential.cleartext_username = 'alice'

    credential.encrypt(team_password)

    credential.save!

    credential = Encryptable::Credentials.find(credential.id)
    credential.decrypt(team_password)

    expect(credential.encryption_algorithm).to eq('AES256')
    expect(credential.cleartext_password).to eq('password')
    expect(credential.cleartext_username).to eq('alice')
  end

  context 'ose secret' do
    let!(:legacy_ose_secret) { create_legacy_ose_secret }

    it 'converts legacy ose secret during decrypt' do
      expect(legacy_ose_secret.send(:legacy_encrypted_data?)).to eq(true)

      legacy_ose_secret.decrypt(team1_password)

      ose_secret = Encryptable::OSESecret.find(legacy_ose_secret.id)

      expect(ose_secret.send(:legacy_encrypted_data?)).to eq(false)

      ose_secret.decrypt(team1_password)
      expect(ose_secret.cleartext_ose_secret).to eq(cleartext_ose_secret)
    end
  end

  private

  def create_legacy_ose_secret
    secret = Encryptable::OSESecret.new(name: 'ose_secret',
                                        folder: folders(:folder1))

    secret.save!
    secret.write_attribute(:encrypted_data, legacy_ose_secret_data)
    secret
  end

  def legacy_ose_secret_data
    encoded_value = FixturesHelper.read_encryptable_file('example_secret_b64.secret')
    value = Base64.strict_decode64(encoded_value)
    { iv: 'Z2eRDQLhiIoCLgNxuunyKw==', value: value }.to_json
  end

  def cleartext_ose_secret
    Base64.strict_decode64(FixturesHelper.read_encryptable_file('example_secret.secret'))
  end
end
