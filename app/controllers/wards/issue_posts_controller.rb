module Wards
  class IssuePostsController < ApplicationController
    before_action :set_ward
    before_action :set_issue

    def create
      @discussion = @issue.discussions.first_or_create!(
        title: @issue.title,
        body: @issue.description,
        user: @issue.created_by,
        status: "open"
      )

      @post = @discussion.posts.build(post_params)
      @post.user = current_user

      if @post.save
        redirect_to ward_issue_path(@ward, @issue), notice: "Comment posted."
      else
        redirect_to ward_issue_path(@ward, @issue), alert: "Could not post comment."
      end
    end

    private

    def set_ward
      @ward = Ward.all.find { |w| w.to_param == params[:ward_id] } || Ward.find_by!(ward_code: params[:ward_id].upcase)
    end

    def set_issue
      @issue = @ward.issues.find(params[:issue_id])
    end

    def post_params
      params.require(:post).permit(:body)
    end
  end
end
