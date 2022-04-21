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
end
