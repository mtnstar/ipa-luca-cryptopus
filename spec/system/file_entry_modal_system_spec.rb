# frozen_string_literal: true

#  Copyright (c) 2008-2017, Puzzle ITC GmbH. This file is part of
#  Cryptopus and licensed under the Affero General Public License version 3 or later.
#  See the COPYING file at the top-level directory or at
#  https://github.com/puzzle/cryptopus.

require 'spec_helper'


describe 'FileEntryModal', type: :system, js: true do
  include SystemHelpers

  let(:bob) { users(:bob) }
  let(:bobs_private_key) { bob.decrypt_private_key('password') }
  let(:plaintext_team_password) { teams(:team1).decrypt_team_password(bob, bobs_private_key) }

  it 'creates and deletes a file entry' do
    allow(Team).to receive(:default_encryption_algorithm).and_return('AES256')

    login_as_user(:bob)

    team = teams(:team1)
    team_password = team.decrypt_team_password(bob, bobs_private_key)

    credentials = encryptables(:credentials1)
    credentials.decrypt(team_password)
    visit("/encryptables/#{credentials.id}")

    expect_encryptable_page_with(credentials)

    # Create File Entry
    file_name = 'test_file.txt'
    file_desc = 'description'
    file_path = "#{Rails.root}/spec/fixtures/files/#{file_name}"
    expect do
      create_new_file_entry(file_desc, file_path)
      expect(page).to have_text(credentials.name)
    end.to change { FileEntry.count }.by(1)

    file_entry = FileEntry.find_by(filename: 'test_file.txt')
    file_content = fixture_file_upload(file_path, 'text/plain').read
    file_entry.decrypt(plaintext_team_password)
    expect(file_entry.cleartext_file).to eq file_content

    expect_encryptable_page_with(credentials)

    # Try to upload again
    expect do
      create_new_file_entry(file_desc, file_path)
    end.to change { FileEntry.count }.by(0)

    expect(page).to have_text('Filename is already taken')
    click_button('Close')

    expect(page).to have_text("Encryptable: #{credentials.name}")

    # Delete File Entry
    del_button = all('img[alt="delete"]')[3]
    expect(del_button).to be_present

    del_button.click
    find('button', text: 'Delete').click
    expect(all('tr').count).to eq(3)
  end

  private

  def create_new_file_entry(description, file_path)
    new_file_entry_button = find('button.btn.btn-primary', text: 'Add Attachment', visible: false)
    new_file_entry_button.click

    expect(page).to have_text('Add new attachment to encryptable')

    expect(find('.modal-content')).to be_present
    expect(page).to have_button('Upload')

    within('div.modal-content') do
      fill_in 'description', with: description
      find(:xpath, "//input[@type='file']", visible: false).attach_file(file_path)
    end

    click_button 'Upload'
  end

  def expect_encryptable_page_with(credentials)
    expect(first('h2')).to have_text("Encryptable: #{credentials.name}")
    expect(find('#cleartext_username').value).to eq(credentials.cleartext_username)
    expect(find('#cleartext_password', visible: false).value).to eq(credentials.cleartext_password)
    expect(page).to have_text(credentials.description)
  end

end
