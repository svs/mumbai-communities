require "test_helper"

class TicketsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:user_one)
    @admin = users(:admin_user)
    @ward = wards(:ward_one)
    @ticket = Ticket.create!(
      title: "Test Ticket",
      description: "Test description",
      ticket_type: "boundary_mapping",
      ward_code: @ward.ward_code,
      status: "open",
      priority: "medium",
      created_by: @user
    )
  end

  test "should get index" do
    get tickets_path
    assert_response :success
  end

  test "should get show" do
    get ticket_path(@ticket)
    assert_response :success
  end
end
