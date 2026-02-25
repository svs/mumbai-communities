class DiscussionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    @discussions = Discussion.not_archived.includes(:user, :category, :discussable)
    @discussions = @discussions.search(params[:q]) if params[:q].present?
    @discussions = @discussions.where(category_id: Category.find_by(slug: params[:category])&.id) if params[:category].present?
    @discussions = @discussions.recent.page(params[:page]).per(20)
    @categories = Category.ordered
  end

  def show
    @discussion = Discussion.find(params[:id])
    @posts = @discussion.posts.roots.includes(:user, replies: [:user, replies: [:user, replies: :user]]).chronological
    @post = @discussion.posts.build
  end
end
