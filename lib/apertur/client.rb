# frozen_string_literal: true

module Apertur
  # Main client for the Apertur API.
  #
  # Provides access to all API resources through lazily initialized accessors.
  # Automatically detects the environment (live vs. sandbox) from the API key
  # prefix and selects the appropriate base URL.
  #
  # @example
  #   client = Apertur::Client.new(api_key: "aptr_test_abc123")
  #   session = client.sessions.create(max_images: 5)
  #   puts session["uuid"]
  class Client
    DEFAULT_BASE_URL = "https://api.aptr.ca"
    SANDBOX_BASE_URL = "https://sandbox.api.aptr.ca"

    # @return [String] the environment this client targets ("live" or "test")
    attr_reader :env

    # @return [Apertur::Resources::Sessions]
    attr_reader :sessions

    # @return [Apertur::Resources::Upload]
    attr_reader :upload

    # @return [Apertur::Resources::Uploads]
    attr_reader :uploads

    # @return [Apertur::Resources::Polling]
    attr_reader :polling

    # @return [Apertur::Resources::Destinations]
    attr_reader :destinations

    # @return [Apertur::Resources::Keys]
    attr_reader :keys

    # @return [Apertur::Resources::Webhooks]
    attr_reader :webhooks

    # @return [Apertur::Resources::Encryption]
    attr_reader :encryption

    # @return [Apertur::Resources::Stats]
    attr_reader :stats

    # Create a new Apertur API client.
    #
    # @param api_key [String, nil] an API key (prefixed +aptr_+ or +aptr_test_+)
    # @param oauth_token [String, nil] an OAuth bearer token (alternative to api_key)
    # @param base_url [String, nil] override the base URL; auto-detected from the
    #   key prefix when nil
    # @raise [ArgumentError] if neither +api_key+ nor +oauth_token+ is provided
    def initialize(api_key: nil, oauth_token: nil, base_url: nil)
      token = api_key || oauth_token
      raise ArgumentError, "Either api_key or oauth_token must be provided" if token.nil? || token.empty?

      @env = token.start_with?("aptr_test_") ? "test" : "live"

      resolved_url = base_url || (@env == "test" ? SANDBOX_BASE_URL : DEFAULT_BASE_URL)
      http = HttpClient.new(resolved_url, token)

      @sessions     = Resources::Sessions.new(http)
      @upload       = Resources::Upload.new(http)
      @uploads      = Resources::Uploads.new(http)
      @polling      = Resources::Polling.new(http)
      @destinations = Resources::Destinations.new(http)
      @keys         = Resources::Keys.new(http)
      @webhooks     = Resources::Webhooks.new(http)
      @encryption   = Resources::Encryption.new(http)
      @stats        = Resources::Stats.new(http)
    end
  end
end
