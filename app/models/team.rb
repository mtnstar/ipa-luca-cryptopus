# frozen_string_literal: true

# == Schema Information
#
# Table name: teams
#
#  id          :integer          not null, primary key
#  name        :string(40)       default(""), not null
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  visible     :boolean          default(TRUE), not null
#  private     :boolean          default(FALSE), not null
#

require_dependency '../utils/crypto/symmetric/aes256'
require_dependency '../utils/crypto/symmetric/aes256iv'

class Team < ApplicationRecord
  attr_readonly :private

  has_many :folders, -> { order :name }, dependent: :destroy
  has_many :teammembers, dependent: :delete_all
  has_many :members, through: :teammembers, source: :user
  has_many :user_favourite_teams, dependent: :destroy, foreign_key: :team_id

  validates :name, presence: true
  validates :encryption_algorithm, presence: true
  validates :name, length: { maximum: 40 }
  validates :description, length: { maximum: 300 }

  after_initialize :set_default_encryption_algorithm

  # Add further algorithms at the bottom
  ENCRYPTION_ALGORITHMS = [
    :AES256,
    :AES256IV
  ].freeze

  enum recrypt_state: {
    failed: 0,
    done: 1,
    in_progress: 2
  }, _prefix: :recrypt

  class << self
    def create(creator, params)
      team = super(params)
      return team unless team.valid?

      plaintext_team_password = Crypto::Symmetric::AES256.random_key
      team.add_user(creator, plaintext_team_password)
      unless team.private?
        User::Human.admins.each do |a|
          team.add_user(a, plaintext_team_password) unless a == creator
        end
      end
      team
    end

    def default_encryption_algorithm
      ENCRYPTION_ALGORITHMS.last
    end
  end

  def label
    name
  end

  def member_candidates
    excluded_user_ids = User::Human.
                        unscoped.joins('LEFT JOIN teammembers ON users.id = teammembers.user_id').
                        where('users.username = "root" OR teammembers.team_id = ?', id).
                        distinct.
                        pluck(:id)
    User::Human.where('id NOT IN(?)', excluded_user_ids)
  end

  def last_teammember?(user_id)
    teammembers.count == 1 && teammember?(user_id)
  end

  def teammember?(user_id)
    teammember(user_id).present?
  end

  def teammember(user_id)
    teammembers.find_by(user_id: user_id)
  end

  def add_user(user, plaintext_team_password)
    raise 'user is already team member' if teammember?(user.id)

    create_teammember(user, plaintext_team_password)
  end

  def remove_user(user)
    teammember(user.id).destroy!
  end

  def decrypt_team_password(user, plaintext_private_key)
    crypted_team_password = teammember(user.id).password
    Crypto::RSA.decrypt(crypted_team_password, plaintext_private_key)
  end

  def password_bytesize
    encryption_algorithm_class.key_bytesize.to_s
  end

  def encryption_algorithm_class
    ::Crypto::Symmetric.const_get(encryption_algorithm)
  end

  def update_encryption_algorithm
    self.encryption_algorithm = ENCRYPTION_ALGORITHMS.last
  end

  private

  def encryption_algortihm=(algortihm)
    write_attribute(:encryption_algorithm, algortihm)
  end

  def uses_default_encryption?
    ENCRYPTION_ALGORITHMS.last == encryption_algorithm.to_sym
  end

  def create_teammember(user, plaintext_team_password)
    encrypted_team_password = Crypto::RSA.encrypt(plaintext_team_password, user.public_key)
    teammembers.create!(password: encrypted_team_password, user: user)
  end

  def set_default_encryption_algorithm
    self.encryption_algorithm = ENCRYPTION_ALGORITHMS.last if self.new_record?
  end
end
