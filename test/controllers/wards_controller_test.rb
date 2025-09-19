require "test_helper"

class WardsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  fixtures :users, :wards, :prabhags, :boundaries

  def setup
    @user = users(:user_one)
    @ward = wards(:ward_A)
  end

  test "should get index" do
    get wards_path
    assert_response :success
  end

  test "should get show" do
    get ward_path(@ward)
    assert_response :success
  end

  test "should get show as JSON without errors" do
    get ward_path(@ward), headers: { 'Accept' => 'application/json' }
    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response.key?('features')
    assert json_response['features'].is_a?(Array)
  end

  test "should allow anonymous access to wards" do
    get wards_path
    assert_response :success

    get ward_path(@ward)
    assert_response :success
  end
end
