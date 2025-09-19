require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_attributes = {
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      name: "Test User"
    }
  end

  test "should get new registration page" do
    get new_user_registration_path
    assert_response :success
    assert_select "form[action='#{user_registration_path}'][method=post]"
    assert_select "input[name='user[email]']"
    assert_select "input[name='user[password]']"
    assert_select "input[name='user[password_confirmation]']"
  end

  test "should create user with valid attributes" do
    assert_difference("User.count") do
      post user_registration_path, params: { user: @user_attributes }
    end

    user = User.find_by(email: @user_attributes[:email])
    assert_not_nil user
    assert_equal @user_attributes[:name], user.name
    assert_equal @user_attributes[:email], user.email

    assert_redirected_to setup_location_path
    follow_redirect!
    assert_response :success
  end

  test "should not create user with invalid email" do
    @user_attributes[:email] = "invalid-email"

    assert_no_difference("User.count") do
      post user_registration_path, params: { user: @user_attributes }
    end

    assert_response :unprocessable_content
    assert_select ".field_with_errors"
  end

  test "should not create user with short password" do
    @user_attributes[:password] = "123"
    @user_attributes[:password_confirmation] = "123"

    assert_no_difference("User.count") do
      post user_registration_path, params: { user: @user_attributes }
    end

    assert_response :unprocessable_content
    assert_select ".field_with_errors"
  end

  test "should not create user with mismatched password confirmation" do
    @user_attributes[:password_confirmation] = "different_password"

    assert_no_difference("User.count") do
      post user_registration_path, params: { user: @user_attributes }
    end

    assert_response :unprocessable_content
    assert_select ".field_with_errors"
  end

  test "should not create user with duplicate email" do
    User.create!(@user_attributes)

    assert_no_difference("User.count") do
      post user_registration_path, params: { user: @user_attributes }
    end

    assert_response :unprocessable_content
    assert_select ".field_with_errors"
  end

  test "should sign in user after successful registration" do
    post user_registration_path, params: { user: @user_attributes }

    assert signed_in?
    user = User.find_by(email: @user_attributes[:email])
    assert_equal user, current_user
  end

  test "should redirect signed in user away from registration" do
    user = users(:user_one)
    sign_in user

    get new_user_registration_path
    assert_redirected_to root_path
  end

  test "should allow user to edit registration" do
    user = users(:user_one)
    sign_in user

    get edit_user_registration_path
    assert_response :success
    assert_select "form[action='#{user_registration_path}'][method=post]"
    assert_select "input[name='user[email]'][value='#{user.email}']"
  end

  test "should update user with valid attributes" do
    user = users(:user_one)
    user.update!(password: "password123", password_confirmation: "password123")
    sign_in user

    new_email = "updated@example.com"
    put user_registration_path, params: {
      user: {
        email: new_email,
        current_password: "password123"
      }
    }

    user.reload
    assert_equal new_email, user.email
    assert_redirected_to root_path
  end

  test "should not update user without current password" do
    user = users(:user_one)
    user.update!(password: "password123", password_confirmation: "password123")
    sign_in user
    old_email = user.email

    put user_registration_path, params: {
      user: {
        email: "updated@example.com"
      }
    }

    user.reload
    assert_equal old_email, user.email
    assert_response :unprocessable_content
  end

  test "should not allow user to delete account" do
    user = users(:user_one)
    user.update!(password: "password123", password_confirmation: "password123")
    sign_in user

    # Account deletion should be prevented to preserve municipal data integrity
    assert_no_difference("User.count") do
      delete user_registration_path
    end

    assert_redirected_to edit_user_registration_path
    assert_match /Account deletion is not allowed/, flash[:alert]
    assert signed_in? # User should remain signed in
  end

  private

  def signed_in?
    !current_user.nil?
  end

  def current_user
    controller.current_user if controller.respond_to?(:current_user)
  end
end