module Prabhags
  class DiscussionsController < ApplicationController
    skip_before_action :authenticate_user!, only: [:index, :show]
    before_action :set_prabhag
    before_action :set_discussion, only: [:show, :edit, :update, :destroy]

    def index
      @discussions = @prabhag.discussions.not_archived.includes(:user, :category)
      @discussions = @discussions.search(params[:q]) if params[:q].present?
      @discussions = @discussions.where(category_id: Category.find_by(slug: params[:category])&.id) if params[:category].present?
      @discussions = @discussions.recent.page(params[:page]).per(20)
      @categories = Category.ordered
    end

    def show
      @posts = @discussion.posts.roots.includes(:user, replies: [:user, replies: [:user, replies: :user]]).chronological
      @post = @discussion.posts.build
    end

    def new
      @discussion = @prabhag.discussions.build
      @categories = Category.ordered
    end

    def create
      @discussion = @prabhag.discussions.build(discussion_params)
      @discussion.user = current_user

      if @discussion.save
        redirect_to prabhag_discussion_path(@prabhag, @discussion), notice: "Discussion created."
      else
        @categories = Category.ordered
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @categories = Category.ordered
    end

    def update
      if @discussion.user == current_user || current_user.admin?
        if @discussion.update(discussion_params)
          redirect_to prabhag_discussion_path(@prabhag, @discussion), notice: "Discussion updated."
        else
          @categories = Category.ordered
          render :edit, status: :unprocessable_entity
        end
      else
        redirect_to prabhag_discussion_path(@prabhag, @discussion), alert: "You can only edit your own discussions."
      end
    end

    def destroy
      if @discussion.user == current_user || current_user.admin?
        @discussion.destroy
        redirect_to prabhag_discussions_path(@prabhag), notice: "Discussion deleted."
      else
        redirect_to prabhag_discussion_path(@prabhag, @discussion), alert: "You can only delete your own discussions."
      end
    end

    private

    def set_prabhag
      @prabhag = Prabhag.find(params[:prabhag_id])
      @ward = @prabhag.ward
    end

    def set_discussion
      @discussion = @prabhag.discussions.find(params[:id])
    end

    def discussion_params
      params.require(:discussion).permit(:title, :body, :category_id)
    end
  end
end
