# frozen_string_literal: true

require_relative "apertur/version"
require_relative "apertur/errors"
require_relative "apertur/http_client"
require_relative "apertur/signature"
require_relative "apertur/crypto"
require_relative "apertur/resources/sessions"
require_relative "apertur/resources/upload"
require_relative "apertur/resources/uploads"
require_relative "apertur/resources/polling"
require_relative "apertur/resources/destinations"
require_relative "apertur/resources/keys"
require_relative "apertur/resources/webhooks"
require_relative "apertur/resources/encryption"
require_relative "apertur/resources/stats"
require_relative "apertur/client"

# Ruby SDK for the Apertur image upload API.
#
# @example Quick start
#   require "apertur"
#
#   client = Apertur::Client.new(api_key: "aptr_test_abc123")
#   session = client.sessions.create(max_images: 5)
#   client.upload.image(session["uuid"], "/path/to/photo.jpg")
#
# @example Verify a webhook signature
#   Apertur::Signature.verify_webhook(request_body, signature_header, secret)
#
# @see Apertur::Client
# @see Apertur::Signature
# @see Apertur::Crypto
module Apertur; end
