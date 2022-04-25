# frozen_string_literal: true

require "test_helper"

class ActionController::StashedRedirectsTest < ActionDispatch::IntegrationTest
  test "stash and recall redirect from a param" do
    get new_session_url, params: { redirect_url: users_url }
    assert_response :no_content

    post sessions_url
    assert_redirected_to users_url
  end

  test "stash and recall redirect from the referer" do
    get new_session_url, headers: { HTTP_REFERER: users_url }
    assert_response :no_content

    post sessions_url
    assert_redirected_to users_url
  end

  test "passing from: block accesses instance context" do
    delete session_url(id: 1)
    assert_redirected_to users_url
  end

  test "cross-controller communication with shared purpose" do
    get new_session_url, params: { redirect_url: users_url }
    assert_response :no_content

    post sessions_redirects_url
    assert_redirected_to users_url
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
      @request ||= Struct.new(:referer) { def get? = true }.new "/users/referer"
    end

    def redirect_to(url, *) = url
    def url_from(url) = url
  end

  include Context, ActionController::StashedRedirects

  test "param takes precedence over referer" do
    stash_redirect_for :sign_in
    assert_equal "/users/param", redirect_from_stashed(:sign_in)
  end

  test "from param" do
    stash_redirect_for :sign_in, from: :param
    assert_equal "/users/param", redirect_from_stashed(:sign_in)
  end

  test "from referer" do
    stash_redirect_for :sign_in, from: :referer
    assert_equal "/users/referer", redirect_from_stashed(:sign_in)
  end

  test "explicit url override" do
    stash_redirect_for :sign_in, from: "/users/explicit"
    assert_equal "/users/explicit", redirect_from_stashed(:sign_in)
  end

  test "no stashed redirect raises" do
    error = assert_raises ActionController::StashedRedirects::MissingRedirectError do
      redirect_from_stashed :sign_in
    end

    assert_equal :sign_in, error.purpose
    assert_match "can't extract a stashed redirect_url to redirect_to", error.message
  end
end
