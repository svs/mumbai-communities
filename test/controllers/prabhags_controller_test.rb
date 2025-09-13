require "test_helper"

class PrabhagsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get prabhags_index_url
    assert_response :success
  end

  test "should get show" do
    get prabhags_show_url
    assert_response :success
  end

  test "should get assign" do
    get prabhags_assign_url
    assert_response :success
  end

  test "should get trace" do
    get prabhags_trace_url
    assert_response :success
  end

  test "should get submit" do
    get prabhags_submit_url
    assert_response :success
  end
end
