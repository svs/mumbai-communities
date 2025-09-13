require "test_helper"

class TicketsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get tickets_index_url
    assert_response :success
  end

  test "should get show" do
    get tickets_show_url
    assert_response :success
  end

  test "should get assign" do
    get tickets_assign_url
    assert_response :success
  end

  test "should get submit" do
    get tickets_submit_url
    assert_response :success
  end
end
