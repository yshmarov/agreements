# frozen_string_literal: true

require "test_helper"

class EnforcementTest < ActionDispatch::IntegrationTest
  test "redirects a pending GET and returns after acceptance" do
    user = create_user
    version = create_version

    get "/protected", params: { user_id: user.id }
    assert_redirected_to "/agreement"

    post "/agreement", params: { user_id: user.id, version_id: version.id }
    assert_redirected_to "/protected?user_id=#{user.id}"

    follow_redirect!
    assert_response :success
    assert_equal "protected", response.body
  end

  test "does not replay or remember a blocked mutation" do
    user = create_user
    version = create_version

    post "/protected", params: { user_id: user.id }
    assert_redirected_to "/agreement"

    post "/agreement", params: { user_id: user.id, version_id: version.id }
    assert_redirected_to "/protected?user_id=#{user.id}"
  end

  test "does not redirect non-HTML requests" do
    user = create_user
    create_version

    get "/protected.json", params: { user_id: user.id }

    assert_response :success
    assert_equal "protected", response.body
  end

  test "rejects unsafe stored return paths" do
    get "/return-path", params: { path: "//attacker.example" }

    assert_response :success
    assert_empty response.body
  end
end
