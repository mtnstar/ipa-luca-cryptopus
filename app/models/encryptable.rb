# frozen_string_literal: true

# == Schema Information
#
# Table name: encryptables
#
#  id          :integer          not null, primary key
#  name         :string(70)       default(""), not null
#  folder_id    :integer          default(0), not null
#  description :text
#  username    :binary
#  password    :binary
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  tag         :string
#

require_dependency '../utils/crypto/symmetric/aes256'
require_dependency '../utils/crypto/symmetric/aes256iv'

class Encryptable < ApplicationRecord

  serialize :encrypted_data, ::EncryptedData

  attr_readonly :type

  validates :type, presence: true
  validates :encryption_algorithm, presence: true

  belongs_to :folder
  has_many :file_entries, foreign_key: :account_id, primary_key: :id, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :folder }
  validates :name, length: { maximum: 70 }
  validates :description, length: { maximum: 4000 }

  after_initialize :set_default_encryption_algorithm

  def encrypt(_team_password)
    raise 'implement in subclass'
  end

  def decrypt(_team_password)
    raise 'implement in subclass'
  end

  def self.policy_class
    EncryptablePolicy
  end

  def label
    name
  end

  def update_encryption_algorithm
    self.encryption_algorithm = Team.default_encryption_algorithm
  end

  def encryption_algorithm_class
    ::Crypto::Symmetric.const_get(encryption_algorithm)
  end

  private

  def encryption_algortihm=(algortihm)
    self[:encryption_algorithm] = algortihm
  end

  def encrypt_attr(attr, team_password)
    cleartext_value = send(:"cleartext_#{attr}")

    data, iv = if cleartext_value.blank?
                 [nil, nil]
               else
                 encryption_algorithm_class.encrypt(cleartext_value, team_password)
               end

    encrypted_data[attr] = { data: data, iv: iv }
  end

  def decrypt_attr(attr, team_password)
    encrypted_value = encrypted_data[attr].try(:[], :data)
    iv = encrypted_data[attr].try(:[], :iv) || nil

    cleartext_value = if encrypted_value
                        encryption_algorithm_class.decrypt(data: encrypted_value,
                                                           key: team_password,
                                                           iv: iv)
                      end

    instance_variable_set("@cleartext_#{attr}", cleartext_value)
  end

  def set_default_encryption_algorithm
    team_encryption_algorithm = folder.team.encryption_algorithm
    self.encryption_algorithm = team_encryption_algorithm
  end
end
