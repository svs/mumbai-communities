require "test_helper"

class PrabhagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_one = users(:user_one)
    @user_two = users(:user_two)
    @prabhag_available = prabhags(:prabhag_available)
    @prabhag_assigned = prabhags(:prabhag_assigned)
    @prabhag_submitted = prabhags(:prabhag_submitted)
    @prabhag_approved = prabhags(:prabhag_approved)
  end

  # Index tests
  test "should get prabhags index" do
    get prabhags_path
    assert_response :success
    assert_select 'h1', text: /Ward Boundary Mapping/i
  end

  test "should get prabhags index with ward filter" do
    get prabhags_path(ward_id: 'A')
    assert_response :success
  end

  # Show tests
  test "should show available prabhag" do
    get prabhag_path(@prabhag_available)
    assert_response :success
    assert_match /Unmapped/, response.body
    assert_match /Help Map This Neighborhood/, response.body
  end

  test "should show assigned prabhag" do
    get prabhag_path(@prabhag_assigned)
    assert_response :success
    assert_match /Mapping in Progress/, response.body
  end

  test "should show submitted prabhag" do
    get prabhag_path(@prabhag_submitted)
    assert_response :success
    assert_match /Under Review/, response.body
  end

  test "should show approved prabhag with community features" do
    get prabhag_path(@prabhag_approved)
    assert_response :success
    assert_match /Active Community/, response.body
    assert_match /Community Actions/, response.body
    assert_match /Community Stats/, response.body
    assert_match /Recent Activity/, response.body
  end

  test "should show prabhag in JSON format" do
    get prabhag_path(@prabhag_available), params: {}, headers: { 'Accept' => 'application/json' }
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal @prabhag_available.number, json_response['number']
    assert_equal @prabhag_available.ward_code, json_response['ward_code']
    assert_equal @prabhag_available.status, json_response['status']
  end

  test "should show approved prabhag community data in JSON" do
    get prabhag_path(@prabhag_approved), params: {}, headers: { 'Accept' => 'application/json' }
    assert_response :success
    json_response = JSON.parse(response.body)
    assert json_response.key?('community')
    assert json_response['community'].key?('stats')
    assert json_response['community'].key?('recent_tickets')
  end

  # Assignment tests
  test "should assign available prabhag to user" do
    sign_in @user_one

    post assign_prabhag_path(@prabhag_available)
    assert_redirected_to trace_prabhag_path(@prabhag_available)

    @prabhag_available.reload
    assert_equal 'assigned', @prabhag_available.status
    assert_equal @user_one, @prabhag_available.assigned_to
  end

  test "should not assign already assigned prabhag" do
    sign_in @user_two

    post assign_prabhag_path(@prabhag_assigned)
    assert_redirected_to prabhag_path(@prabhag_assigned)
    assert_match /not available/, flash[:alert]
  end

  test "should require login for assignment" do
    post assign_prabhag_path(@prabhag_available)
    assert_redirected_to new_user_session_path
  end

  # Trace tests
  test "should show trace page for assigned prabhag" do
    sign_in @user_one
    get trace_prabhag_path(@prabhag_assigned)
    assert_response :success
  end

  test "should deny access to trace if not assigned user" do
    sign_in @user_two
    get trace_prabhag_path(@prabhag_assigned)
    assert_redirected_to prabhag_path(@prabhag_assigned)
    assert_match /Access denied/, flash[:alert]
  end

  test "should require login for trace" do
    get trace_prabhag_path(@prabhag_assigned)
    assert_redirected_to new_user_session_path
  end

  # Submit tests
  test "should submit boundary for assigned prabhag" do
    sign_in @user_one

    geojson = '{"type":"Polygon","coordinates":[[[72.84,19.14],[72.85,19.14],[72.85,19.15],[72.84,19.15],[72.84,19.14]]]}'

    post submit_prabhag_path(@prabhag_assigned), params: { boundary_geojson: geojson }
    assert_redirected_to prabhag_path(@prabhag_assigned)
    assert_match /submitted for review/, flash[:notice]

    @prabhag_assigned.reload
    assert_equal 'submitted', @prabhag_assigned.status
  end

  test "should not submit boundary without geojson" do
    sign_in @user_one

    post submit_prabhag_path(@prabhag_assigned)
    assert_redirected_to trace_prabhag_path(@prabhag_assigned)
    assert_match /Please trace the boundary/, flash[:alert]
  end

  test "should not submit if not assigned user" do
    sign_in @user_two

    post submit_prabhag_path(@prabhag_assigned), params: { boundary_geojson: '{"test": "data"}' }
    assert_redirected_to prabhag_path(@prabhag_assigned)
    assert_match /Access denied/, flash[:alert]
  end

  # Nested route tests (ward context)
  test "should show prabhag within ward context" do
    get ward_prabhag_path('ward-a', @prabhag_available.number)
    assert_response :success
    assert_match /Ward A/, response.body
  end

  test "should handle ward slug conversion" do
    get ward_prabhag_path('ward-a', @prabhag_available.number)
    assert_response :success
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: 'password'
      }
    }
  end
end
