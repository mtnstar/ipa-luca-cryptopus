# frozen_string_literal: true

class Recrypt::EncryptablesController < ApplicationController
  include EncryptablesRecrypt

  def new
    authorize_action :new
    recrypt_user_encryptables
    render layout: false
  end

  private


  def recrypt_user_encryptables
    user_recrypt_teams.each do |team|
      new_team_password = team.reset_team_password
      recrypt_encryptables(team, new_team_password)
    end
  end

  def recrypt_encryptables(team, new_team_password)
    old_team_password = team.decrypt_team_password(current_user, session[:private_key])

    ActiveRecord::Base.transaction do
      entailed_encryptables(team).each do

      end
    end
  end

  def entailed_encryptables(team)
    team.folders.map(&:encryptables).flatten
  end

  def authorize_action(action)
    authorize action, policy_class: Recrypt::EncryptablesPolicy
  end
end
