class Admin::DiscussionsController < Admin::BaseController
  before_action :set_discussion, only: [:show, :close, :reopen, :archive, :pin, :unpin]

  def index
    @discussions = Discussion.includes(:user, :discussable, :category).order(created_at: :desc).page(params[:page]).per(25)
    @discussions = @discussions.where(status: params[:status]) if params[:status].present?
  end

  def show
    @posts = @discussion.posts.includes(:user).order(:created_at)
  end

  def close
    @discussion.close!
    redirect_to admin_discussion_path(@discussion), notice: "Discussion closed."
  end

  def reopen
    @discussion.reopen!
    redirect_to admin_discussion_path(@discussion), notice: "Discussion reopened."
  end

  def archive
    @discussion.archive!
    redirect_to admin_discussions_path, notice: "Discussion archived."
  end

  def pin
    @discussion.pin!
    redirect_to admin_discussion_path(@discussion), notice: "Discussion pinned."
  end

  def unpin
    @discussion.unpin!
    redirect_to admin_discussion_path(@discussion), notice: "Discussion unpinned."
  end

  private

  def set_discussion
    @discussion = Discussion.find(params[:id])
  end
end
