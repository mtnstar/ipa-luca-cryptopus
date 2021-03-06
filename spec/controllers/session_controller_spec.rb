# frozen_string_literal: true

require 'spec_helper'

describe SessionController do
  include ControllerHelpers

  context 'GET new' do

    it 'should show 401 if ip address is unauthorized' do
      expect_any_instance_of(Authentication::SourceIpChecker)
        .to receive(:ip_authorized?)
        .and_return(false)

      get :new

      expect(response).to have_http_status(401)
    end

    it 'saves ip in session if ip allowed' do
      random_ip = "#{rand(1..253)}.#{rand(254)}.#{rand(254)}.#{rand(254)}"
      expect_any_instance_of(Authentication::SourceIpChecker)
        .to receive(:ip_authorized?)
        .and_return(true)
      expect_any_instance_of(ActionController::TestRequest)
        .to receive(:remote_ip)
        .exactly(3).times
        .and_return(random_ip)

      get :new

      expect(response).to have_http_status(200)
      expect(session[:authorized_ip]).to eq random_ip
    end

  end

  context 'DELETE destroy' do
    it 'logs in and logs out' do
      login_as(:bob)

      delete :destroy

      expect(response).to redirect_to session_new_path
    end

    it 'logs in, logs out and save jumpto if set' do
      login_as(:admin)

      delete :destroy, params: { jumpto: '/teams' }

      expect(response).to redirect_to session_new_path
      expect('/teams').to eq session[:jumpto]
    end
  end

  context 'POST create' do
    it 'cannot login with wrong password' do
      post :create, params: { password: 'wrong_password', username: 'bob' }

      expect(flash[:error]).to match(/Authentication failed/)
    end

    it 'redirects to recryptrequests page if private key cannot be decrypted' do
      users(:bob).update!(private_key: 'invalid private_key')

      post :create, params: { password: 'password', username: 'bob' }

      expect(response).to redirect_to session_new_path
    end

    it 'cannot login with unknown username' do
      post :create, params: { password: 'password', username: 'baduser' }

      expect(flash[:error]).to match(/Authentication failed/)
    end

    it 'cannot login without username' do
      post :create, params: { password: 'password' }

      expect(flash[:error]).to match(/Authentication failed/)
    end

    it 'updates last login at if user logs in' do
      time = Time.zone.now
      expect_any_instance_of(ActiveSupport::TimeZone).to receive(:now).and_return(time)

      post :create, params: { password: 'password', username: 'bob' }

      users(:bob).reload
      expect(users(:bob).last_login_at.to_s).to eq time.to_s
    end

    it 'shows last login datetime and ip without country' do
      expect(GeoIp).to receive(:activated?).and_return(false).at_least(:once)

      user = users(:bob)
      user.update!(last_login_at: '2017-01-01 16:00:00 + 0000', last_login_from: '192.168.210.10')

      post :create, params: { password: 'password', username: 'bob' }
    end

    it 'does not show last login date if not available' do
      users(:bob).update!(last_login_at: nil)
      post :create, params: { password: 'password', username: 'bob' }
      expect(flash[:notice]).to be_nil
    end

    it 'does not show previous login ip if not available' do
      user = users(:bob)
      user.update!(last_login_at: '2017-01-01 16:00:00 + 0000', last_login_from: nil)

      post :create, params: { password: 'password', username: 'bob' }
    end

    it 'redirects to encryptables recrypt if user teams need recrypt' do
      user = users(:bob)
      Team.create(user, name: 'Puzzle Members').save!

      post :create, params: { password: 'password', username: 'bob' }

      expect(response).to redirect_to recrypt_encryptables_path
    end

    it 'skips recrypt if no user teams need recrypt' do
      user = users(:alice)
      user.teams.first.remove_user(user).save

      Team.create(user, name: 'Puzzle Members').save!

      post :create, params: { password: 'password', username: 'alice' }

      expect(response).to redirect_to 'http://test.host/dashboard'
    end
  end
end
