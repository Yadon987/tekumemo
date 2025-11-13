require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    user = users(:one)
    sign_in user

    get root_url
    assert_response :success
  end
end
