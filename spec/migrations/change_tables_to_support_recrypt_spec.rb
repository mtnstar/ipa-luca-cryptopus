# frozen_string_literal: true

require 'spec_helper'

migration_dir = 'db/migrate/'

migration_file_name = '20220304091836_change_tables_to_support_recrypt.rb'
migration_file = Dir[Rails.root.join(migration_dir + migration_file_name)].first

require migration_file

describe ChangeTablesToSupportRecrypt do

  let(:migration) { described_class.new }

  let!(:team1) { teams(:team1) }

  let!(:credentials1) { encryptables(:credentials1) }

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
      migration.down
    end

    it 'adds encryption columns to team and encryptable' do
      migration.up

      team1.reload
      expect(team1.encryption_algorithm).to eq('AES256')
      expect(team1.recrypt_state).to eq('done')

      credentials1.reload
      expect(credentials1.encryption_algorithm).to eq('AES256')

      new_credential = Encryptable::Credentials.create!(encryption_algorithm: team1.encryption_algorithm,
                                                    name: 'Google Account')
      expect(new_credential.encryption_algorithm).to eq('AES256')
    end
  end

  context 'down' do

    it 'migrates back to previous state, without recrypt columns' do
      migration.down
      require 'pry'; binding.pry unless $pstop
      team1.reload
      expect(team1.encryption_algorithm).to eq(nil)
      expect(team1.recrypt_state).to eq(nil)

      credentials1.reload
      expect do
        credentials1.encryption_algorithm
      end.to raise_error(ActiveModel::MissingAttributeError)

      expect do
        Encryptable::Credentials.create!(encryption_algorithm: team1.encryption_algorithm,
                                                          name: 'Google Account')
      end.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

end
