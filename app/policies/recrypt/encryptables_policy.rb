# frozen_string_literal: true

class Recrypt::EncryptablesPolicy < ApplicationPolicy
  def new?
    user.present?
  end
end
