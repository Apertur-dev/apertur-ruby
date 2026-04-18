# frozen_string_literal: true

require "openssl"

module Apertur
  # Webhook signature verification utilities.
  #
  # Provides constant-time signature verification for three webhook formats
  # used by the Apertur platform.
  module Signature
    module_function

    # Verify an image delivery webhook signature.
    #
    # The signature header is formatted as +sha256=<hex>+ and is computed as
    # +HMAC-SHA256(body, secret)+.
    #
    # @param body [String] the raw request body
    # @param signature [String] the signature header value (e.g. "sha256=abc123...")
    # @param secret [String] the webhook signing secret
    # @return [Boolean] true if the signature is valid
    def verify_webhook(body, signature, secret)
      expected = OpenSSL::HMAC.hexdigest("SHA256", secret, body)
      sig = signature.start_with?("sha256=") ? signature[7..] : signature
      secure_compare(expected, sig)
    end

    # Verify an event webhook signature (HMAC SHA256 method).
    #
    # The signed payload is +"\#{timestamp}.\#{body}"+ and the signature header
    # is formatted as +sha256=<hex>+.
    #
    # @param body [String] the raw request body
    # @param timestamp [String] the X-Apertur-Timestamp header value
    # @param signature [String] the X-Apertur-Signature header value
    # @param secret [String] the webhook signing secret
    # @return [Boolean] true if the signature is valid
    def verify_event(body, timestamp, signature, secret)
      signature_base = "#{timestamp}.#{body}"
      expected = OpenSSL::HMAC.hexdigest("SHA256", secret, signature_base)
      sig = signature.start_with?("sha256=") ? signature[7..] : signature
      secure_compare(expected, sig)
    end

    # Verify an event webhook signature (Svix method).
    #
    # The signed payload is +"\#{svix_id}.\#{timestamp}.\#{body}"+ and the
    # signing key is the secret decoded from hex. The signature header is
    # formatted as +v1,<base64>+.
    #
    # @param body [String] the raw request body
    # @param svix_id [String] the svix-id header value
    # @param timestamp [String] the svix-timestamp header value
    # @param signature [String] the svix-signature header value (e.g. "v1,base64...")
    # @param secret [String] the webhook signing secret (hex-encoded)
    # @return [Boolean] true if the signature is valid
    def verify_svix(body, svix_id, timestamp, signature, secret)
      signature_base = "#{svix_id}.#{timestamp}.#{body}"
      key = [secret].pack("H*")
      expected = OpenSSL::HMAC.digest("SHA256", key, signature_base)
      expected_b64 = [expected].pack("m0")
      sig = signature.start_with?("v1,") ? signature[3..] : signature
      secure_compare(expected_b64, sig)
    end

    # Constant-time string comparison to prevent timing attacks.
    #
    # @param a [String]
    # @param b [String]
    # @return [Boolean]
    def secure_compare(a, b)
      return false unless a.bytesize == b.bytesize

      OpenSSL.fixed_length_secure_compare(a, b)
    rescue StandardError
      false
    end
  end
end
