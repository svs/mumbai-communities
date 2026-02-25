class Admin::UsersController < Admin::BaseController
  def index
    @users = User.order(:name)
  end
end
