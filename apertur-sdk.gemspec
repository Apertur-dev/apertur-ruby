# frozen_string_literal: true

require_relative "lib/apertur/version"

Gem::Specification.new do |spec|
  spec.name          = "apertur-sdk"
  spec.version       = Apertur::VERSION
  spec.authors       = ["Apertur"]
  spec.email         = ["support@aptr.ca"]

  spec.summary       = "Ruby SDK for the Apertur API"
  spec.description   = "Official Ruby client for the Apertur image upload and delivery API. " \
                        "Supports session management, image uploads (including client-side " \
                        "encryption), polling, destinations, webhooks, and more."
  spec.homepage      = "https://github.com/Apertur-dev/apertur-ruby"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/Apertur-dev/apertur-ruby",
    "changelog_uri" => "https://github.com/Apertur-dev/apertur-ruby/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://docs.apertur.ca",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb"] + ["LICENSE", "README.md"]
  spec.require_paths = ["lib"]
end
