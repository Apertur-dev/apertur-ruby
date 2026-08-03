# frozen_string_literal: true

require "openssl"
require "base64"
require "securerandom"

module Apertur
  # Image encryption utilities for client-side encryption before upload.
  #
  # Uses AES-256-GCM for symmetric encryption and RSA-OAEP (SHA-256) to
  # wrap the AES key with the server's public key.
  module Crypto
    module_function

    # Encrypt image data for secure upload.
    #
    # Generates a random AES-256-GCM key and IV, encrypts the image data,
    # then wraps the AES key with the provided RSA public key using OAEP
    # padding with SHA-256.
    #
    # @param image_data [String] raw image bytes
    # @param public_key_pem [String] RSA public key in PEM format
    # @return [Hash] a Hash with the following String keys:
    #   - +"encrypted_key"+ - Base64-encoded RSA-wrapped AES key
    #   - +"iv"+ - Base64-encoded initialization vector
    #   - +"encrypted_data"+ - Base64-encoded ciphertext with appended GCM auth tag
    #   - +"algorithm"+ - the encryption algorithm identifier ("RSA-OAEP+AES-256-GCM")
    def encrypt_image(image_data, public_key_pem)
      # Generate random AES-256 key and 12-byte IV
      aes_key = SecureRandom.random_bytes(32)
      iv = SecureRandom.random_bytes(12)

      # Encrypt image with AES-256-GCM
      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.encrypt
      cipher.key = aes_key
      cipher.iv = iv

      encrypted = cipher.update(image_data) + cipher.final
      auth_tag = cipher.auth_tag
      encrypted_with_tag = encrypted + auth_tag

      # Wrap AES key with RSA-OAEP (SHA-256)
      # Uses OpenSSL::PKey::PKey#encrypt (available in Ruby 3.0+) which
      # allows specifying the OAEP digest algorithm.
      pub_key = OpenSSL::PKey::RSA.new(public_key_pem)
      wrapped_key = pub_key.encrypt(aes_key, {
        "rsa_padding_mode" => "oaep",
        "rsa_oaep_md" => "sha256"
      })

      {
        "encrypted_key" => Base64.strict_encode64(wrapped_key),
        "iv" => Base64.strict_encode64(iv),
        "encrypted_data" => Base64.strict_encode64(encrypted_with_tag),
        "algorithm" => "RSA-OAEP+AES-256-GCM"
      }
    end
  end
end
