class Users::RegistrationsController < Devise::RegistrationsController
  # Override destroy to prevent account deletion
  # Municipal boundary data must be preserved for data integrity
  def destroy
    redirect_to edit_user_registration_path, alert: 'Account deletion is not allowed. Contact an administrator for account management.'
  end
end