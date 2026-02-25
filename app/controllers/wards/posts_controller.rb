module Wards
  class PostsController < ApplicationController
    before_action :set_ward
    before_action :set_discussion
    before_action :set_post, only: [:edit, :update, :destroy]

    def create
      @post = @discussion.posts.build(post_params)
      @post.user = current_user

      if @post.save
        redirect_to ward_discussion_path(@ward, @discussion, anchor: "post-#{@post.id}"), notice: "Reply posted."
      else
        @posts = @discussion.posts.roots.includes(:user, replies: [:user, replies: [:user, replies: :user]]).chronological
        render "wards/discussions/show", status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @post.user == current_user || current_user.admin?
        if @post.update(post_params)
          redirect_to ward_discussion_path(@ward, @discussion, anchor: "post-#{@post.id}"), notice: "Reply updated."
        else
          render :edit, status: :unprocessable_entity
        end
      else
        redirect_to ward_discussion_path(@ward, @discussion), alert: "You can only edit your own replies."
      end
    end

    def destroy
      if @post.user == current_user || current_user.admin?
        @post.destroy
        redirect_to ward_discussion_path(@ward, @discussion), notice: "Reply deleted."
      else
        redirect_to ward_discussion_path(@ward, @discussion), alert: "You can only delete your own replies."
      end
    end

    private

    def set_ward
      @ward = Ward.all.find { |w| w.to_param == params[:ward_id] } || Ward.find_by!(ward_code: params[:ward_id].upcase)
    end

    def set_discussion
      @discussion = @ward.discussions.find(params[:discussion_id])
    end

    def set_post
      @post = @discussion.posts.find(params[:id])
    end

    def post_params
      params.require(:post).permit(:body, :parent_id)
    end
  end
end
