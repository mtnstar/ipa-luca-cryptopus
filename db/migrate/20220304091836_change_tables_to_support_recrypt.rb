# frozen_string_literal: true

class ChangeTablesToSupportRecrypt < ActiveRecord::Migration[6.1]
  def up
    add_column :teams, :recrypt_state, :integer, default: 1, null: false
    add_column :teams, :encryption_algorithm, :string, default: 'AES256', null: false

    add_column :encryptables, :encryption_algorithm, :string, default: 'AES256', null: false
  end

  def down
    remove_column :teams, :recrypt_state
    remove_column :teams, :encryption_algorithm

    remove_column :encryptables, :encryption_algorithm
  end
end
