require "test_helper"

class Admin::PrabhagsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get admin_prabhags_index_url
    assert_response :success
  end

  test "should get show" do
    get admin_prabhags_show_url
    assert_response :success
  end

  test "should get approve" do
    get admin_prabhags_approve_url
    assert_response :success
  end

  test "should get reject" do
    get admin_prabhags_reject_url
    assert_response :success
  end
end
