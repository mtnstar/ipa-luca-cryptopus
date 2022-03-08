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

      expect(response).to have_http_status 302
      expect(team1.encryption_algorithm).to eq('AES256IV')
      expect(team1.recrypt_state).to eq('done')
      expect(encryptable1.encryption_algorithm).to eq('AES256IV')
    end

    it 'starts new unsuccessful encryptables recrypt for user Teams' do
      login_as(:alice)
      team1 = teams(:team1)

      allow_any_instance_of(Team).to receive(:encryption_algorithm).and_return('AES256')

      get :new

      expect(response).to have_http_status 302
      expect(team1.encryption_algorithm).to eq('AES256IV')
      expect(team1.recrypt_state).to eq('done')
      expect(team1.recrypt_state).to eq('done')
    end
  end

end
