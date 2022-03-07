# frozen_string_literal: true

module EncryptablesRecrypt
  extend ActiveSupport::Concern

  RECRYPT_DONE_STATE = 1

  def user_recrypt_teams
    current_user.teams.where("recrypt_state = ? AND encryption_algorithm != ?",
                             RECRYPT_DONE_STATE,
                             Team.default_encryption_algorithm)
  end
end
