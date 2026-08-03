# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/apertur"

class SigningTest < Minitest::Test
  SECRET = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

  def test_known_answer_vector_with_body
    result = Apertur::Signature.sign_request(SECRET, "POST", "/api/v1/upload-sessions", '{"a":1}', 1_800_000_000)

    assert_equal(
      {
        "X-Aptr-Signature" => "sha256=d5bf88c946aa6cf4397749eacd05cf058e6828878f9b1c84830cb7c07a234d3e",
        "X-Aptr-Timestamp" => "1800000000"
      },
      result
    )
  end

  def test_known_answer_vector_with_nil_body
    result = Apertur::Signature.sign_request(SECRET, "GET", "/api/v1/uploads/abc", nil, 1_800_000_000)

    assert_equal "sha256=f53cf714f69187170c4fdb22c53e0b53578dcbcb61e63b56948d5e1fd8294a3e", result["X-Aptr-Signature"]
    assert_equal "1800000000", result["X-Aptr-Timestamp"]
  end

  def test_method_is_uppercased
    lower = Apertur::Signature.sign_request(SECRET, "get", "/api/v1/uploads/abc", nil, 1_800_000_000)
    upper = Apertur::Signature.sign_request(SECRET, "GET", "/api/v1/uploads/abc", nil, 1_800_000_000)
    mixed = Apertur::Signature.sign_request(SECRET, "GeT", "/api/v1/uploads/abc", nil, 1_800_000_000)

    assert_equal upper, lower
    assert_equal upper, mixed
  end

  def test_symbol_method_is_accepted_and_uppercased
    result = Apertur::Signature.sign_request(SECRET, :get, "/api/v1/uploads/abc", nil, 1_800_000_000)

    assert_equal "sha256=f53cf714f69187170c4fdb22c53e0b53578dcbcb61e63b56948d5e1fd8294a3e", result["X-Aptr-Signature"]
  end

  def test_empty_string_body_matches_nil_body
    with_nil = Apertur::Signature.sign_request(SECRET, "GET", "/api/v1/uploads/abc", nil, 1_800_000_000)
    with_empty = Apertur::Signature.sign_request(SECRET, "GET", "/api/v1/uploads/abc", "", 1_800_000_000)

    assert_equal with_nil, with_empty
  end

  def test_http_client_omits_signing_headers_when_no_secret_configured
    http = Apertur::HttpClient.new("https://api.aptr.ca", "aptr_test_abc")

    assert_equal({}, http.send(:sign_headers, "GET", "/api/v1/uploads/abc", nil))
  end

  def test_http_client_signs_when_secret_configured
    http = Apertur::HttpClient.new("https://api.aptr.ca", "aptr_test_abc", signing_secret: SECRET)

    headers = http.send(:sign_headers, "GET", "/api/v1/uploads/abc", nil)

    assert headers.key?("X-Aptr-Signature")
    assert headers.key?("X-Aptr-Timestamp")
    assert headers["X-Aptr-Signature"].start_with?("sha256=")
  end
end
