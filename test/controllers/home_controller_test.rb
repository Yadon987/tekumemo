require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index with authenticated user" do
    user = users(:one)
    user.password = "password"
    user.password_confirmation = "password"
    user.save!

    sign_in user
    get root_url
    assert_response :success
  end
end
