class ChangeTablesToSupportRecrypt < ActiveRecord::Migration[6.1]
  def change
    add_column :teams, :recrypt_state, :integer, default: 1
    add_column :teams, :encryption_algorithm, :string, default: 'AES256'

    add_column :encryptables, :encryption_algorithm, :string, default: 'AES256'
  end
end
