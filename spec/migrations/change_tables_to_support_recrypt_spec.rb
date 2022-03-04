# frozen_string_literal: true

require 'spec_helper'

migration_dir = 'db/migrate/'

migration_file_name = '20220304091836_change_tables_to_support_recrypt.rb'
migration_file = Dir[Rails.root.join(migration_dir + migration_file_name)].first

require migration_file

describe ChangeTablesToSupportRecrypt do

  let(:migration) { described_class.new }

  let!(:team1) { teams(:team1) }

  let!(:folder1) { folders(:folder1) }

  let!(:credentials1) { encryptables(:credentials1) }
  let!(:file1) { encryptables(:file1) }

  def silent
    verbose = ActiveRecord::Migration.verbose = false

    yield

    ActiveRecord::Migration.verbose = verbose
  end

  around do |test|
    silent { test.run }
  end

  context 'up' do

    before do
      rename_accounts_to_encryptables_migration.down
      migration.down

      @team1 = Team.create!(name: 'Puzzle Members', description: 'Puzzle team')

      @credentials3 = LegacyAccountCredentialsBefore.create!(accountname: 'spacex', username: '',
                                                         password: nil)

      @ose_secret1 = LegacyAccountCredentialsBefore.create!(accountname: 'spacex', username: '',
                                                         password: nil)
    end

    it 'adds encryption columns to team and encryptable' do
      migration.up

    end

  end

  context 'down' do

    before do
      rename_accounts_to_encryptables_migration.down
    end

    it 'migrates back to encrypted username, password blob fields' do
      @account3 = LegacyAccountCredentialsAfter.create!(name: 'spacex', folder_id: folder1.id)

      migration.down

      # account 1
      legacy_account = LegacyAccountCredentialsBefore.find(credentials1.id)

      raw_encrypted_data = legacy_account.read_attribute_before_type_cast(:encrypted_data)
      expect(raw_encrypted_data).to eq('{}')

      legacy_account.decrypt(team1_password)

      expect(legacy_account.cleartext_username).to eq('test')
      expect(legacy_account.cleartext_password).to eq('password')

      # account 2
      legacy_account = LegacyAccountCredentialsBefore.find(credentials2.id)

      raw_encrypted_data = legacy_account.read_attribute_before_type_cast(:encrypted_data)
      expect(raw_encrypted_data).to eq('{}')

      legacy_account.decrypt(team2_password)

      expect(legacy_account.cleartext_username).to eq('test2')
      expect(legacy_account.cleartext_password).to eq('password')

      # account 3
      legacy_account = LegacyAccountCredentialsBefore.find_by(id: @account3.id)

      raw_encrypted_data = legacy_account.read_attribute_before_type_cast(:encrypted_data)
      expect(raw_encrypted_data).to eq('{}')

      legacy_account.decrypt(team1_password)

      expect(legacy_account.cleartext_username).to eq(nil)
      expect(legacy_account.cleartext_password).to eq(nil)
    end
  end

end
