# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../../app/utils/crypto/symmetric/aes256'
require_relative '../../../../../app/utils/crypto/rsa'

describe Crypto::Symmetric::AES256 do

  let(:keypair) { Crypto::RSA.generate_new_keypair }
  let(:private_key) { keypair.to_s }
  let(:public_key) { keypair.public_key.to_s }
  let(:team_password) { Crypto::Symmetric::AES256.random_key }

  it 'encrypts and decrypts private key' do
    encrypted_private_key = Crypto::Symmetric::AES256.encrypt_with_salt(private_key, team_password)
    decrypted_private_key = Crypto::Symmetric::AES256.decrypt_with_salt(
      encrypted_private_key,
      team_password
    )
    expect(private_key).to eq(decrypted_private_key)
  end

  it 'encrypts and decrypts data' do
    cleartext_data = Base64.decode64('test')
    cleartext_data_encrypted, = Crypto::Symmetric::AES256.encrypt(cleartext_data, team_password)
    result = Crypto::Symmetric::AES256.decrypt(data: cleartext_data_encrypted,
                                               key: team_password)
    expect(cleartext_data.force_encoding('UTF-8')).to eq(result)
  end
end
