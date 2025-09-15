module AdminAuthorizable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    before_action :ensure_admin!
  end

  private

  def ensure_admin!
    redirect_to root_path, alert: 'Access denied. Admin privileges required.' unless current_user&.admin?
  end
end