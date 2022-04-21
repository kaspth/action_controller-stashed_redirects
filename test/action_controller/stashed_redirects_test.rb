# frozen_string_literal: true

require "test_helper"

class ActionController::StashedRedirectsTest < ActionDispatch::IntegrationTest
  test "stash and recall redirect from a param" do
    get new_session_path, params: { redirect_url: users_path }
    assert_response :no_content

    post sessions_path
    assert_redirected_to users_path
  end

  test "stash and recall redirect from the referer" do
    get new_session_path, headers: { HTTP_REFERER: users_path }
    assert_response :no_content

    post sessions_path
    assert_redirected_to users_path
  end
end
