class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :password, :password_confirmation])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :email, :password, :password_confirmation, :current_password])
  end

  def after_sign_up_path_for(resource)
    if resource.needs_location_setup?
      setup_location_path
    else
      root_path
    end
  end

  def after_sign_in_path_for(resource)
    if resource.needs_location_setup?
      setup_location_path
    else
      stored_location_for(resource) || root_path
    end
  end
end
