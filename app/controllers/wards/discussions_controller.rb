module Wards
  class DiscussionsController < ApplicationController
    skip_before_action :authenticate_user!, only: [:index, :show]
    before_action :set_ward
    before_action :set_discussion, only: [:show, :edit, :update, :destroy]

    def index
      @discussions = @ward.discussions.not_archived.includes(:user, :category)
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
      @discussion = @ward.discussions.build
      @categories = Category.ordered
    end

    def create
      @discussion = @ward.discussions.build(discussion_params)
      @discussion.user = current_user

      if @discussion.save
        redirect_to ward_discussion_path(@ward, @discussion), notice: "Discussion created."
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
          redirect_to ward_discussion_path(@ward, @discussion), notice: "Discussion updated."
        else
          @categories = Category.ordered
          render :edit, status: :unprocessable_entity
        end
      else
        redirect_to ward_discussion_path(@ward, @discussion), alert: "You can only edit your own discussions."
      end
    end

    def destroy
      if @discussion.user == current_user || current_user.admin?
        @discussion.destroy
        redirect_to ward_discussions_path(@ward), notice: "Discussion deleted."
      else
        redirect_to ward_discussion_path(@ward, @discussion), alert: "You can only delete your own discussions."
      end
    end

    private

    def set_ward
      @ward = Ward.all.find { |w| w.to_param == params[:ward_id] } || Ward.find_by!(ward_code: params[:ward_id].upcase)
    end

    def set_discussion
      @discussion = @ward.discussions.find(params[:id])
    end

    def discussion_params
      params.require(:discussion).permit(:title, :body, :category_id)
    end
  end
end
