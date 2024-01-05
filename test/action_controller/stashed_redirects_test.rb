# frozen_string_literal: true

require "test_helper"

class ActionController::StashedRedirectsTest < ActionDispatch::IntegrationTest
  test "version" do
    assert ActionController::StashedRedirects::VERSION
  end

  test "stash and recall redirect from a param" do
    get new_session_url, params: { redirect_url: users_url }
    assert_response :no_content

    post sessions_url
    assert_redirected_to users_url
  end

  test "passing url: block accesses instance context" do
    delete session_url(id: 1)
    assert_redirected_to users_url
  end

  test "cross-controller communication with shared purpose" do
    get new_session_url, params: { redirect_url: users_url }
    assert_response :no_content

    post sessions_redirects_url
    assert_redirected_to users_url
  end

  test "passing a non-existent redirect_url on action that expects it raises" do
    get new_session_url
    assert_response :internal_server_error
  end
end

class ActionController::StashedRedirects::HooksTest < ActiveSupport::TestCase
  module Context
    def session
      @session ||= {}
    end

    def params
      @params ||= { redirect_url: "/users/param" }
    end

    def request
      @request ||= Struct.new(:host, :referer) { def get? = true }.new "http://example.com", "/users/referer"
    end

    def redirect_to(url, *) = url

    def url_from(url)
      if url.present?
        url if URI(url.to_s).host.then { _1.nil? || _1 == request.host }
      end
    end
  end

  include Context, ActionController::StashedRedirects

  test "from redirect_url" do
    stash_redirect_for :sign_in
    assert_equal "/users/param", redirect_from_stashed(:sign_in)
  end

  test "explicit url override" do
    stash_redirect_for :sign_in, url: "/users/explicit"
    assert_equal "/users/explicit", redirect_from_stashed(:sign_in)
  end

  test "passing the wrong URL raises" do
    assert_raises(ArgumentError) { stash_redirect_for :sign_in, url: nil }
    assert_raises(ArgumentError) { stash_redirect_for :sign_in, url: "http://google.com" }
  end

  test "no stashed redirect raises" do
    error = assert_raises ActionController::StashedRedirects::MissingRedirectError do
      redirect_from_stashed :sign_in
    end

    assert_equal :sign_in, error.purpose
    assert_match "can't extract a stashed redirect_url to redirect_to", error.message
  end
end
