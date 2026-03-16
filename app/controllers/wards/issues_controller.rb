module Wards
  class IssuesController < ApplicationController
    skip_before_action :authenticate_user!, only: [:index, :show]
    before_action :set_ward
    before_action :set_issue, only: [:show, :close, :reopen]

    def index
      @issues = @ward.issues.includes(:created_by, :category).recent
      @issues = @issues.where(category: Category.find_by(slug: params[:category])) if params[:category].present?
      @categories = Category.ordered
    end

    def show
      @todo_items = @issue.todo_items.ordered
      @discussions = @issue.discussions.not_archived.recent
      @post = Post.new
    end

    def new
      if params[:tweet_id]
        @tweet = @ward.tweets.find(params[:tweet_id])
        @issue = Issue.from_tweet(@tweet)
      else
        @issue = @ward.issues.build
      end
      @categories = Category.ordered
    end

    def create
      @issue = @ward.issues.build(issue_params)
      @issue.created_by = current_user

      if @issue.save
        redirect_to ward_issue_path(@ward, @issue), notice: "Issue created."
      else
        @tweet = @issue.tweet
        @categories = Category.ordered
        render :new, status: :unprocessable_entity
      end
    end

    def close
      @issue.close!
      redirect_to ward_issue_path(@ward, @issue), notice: "Issue closed."
    end

    def reopen
      @issue.reopen!
      redirect_to ward_issue_path(@ward, @issue), notice: "Issue reopened."
    end

    private

    def set_ward
      @ward = Ward.all.find { |w| w.to_param == params[:ward_id] } || Ward.find_by!(ward_code: params[:ward_id].upcase)
    end

    def set_issue
      @issue = @ward.issues.find(params[:id])
    end

    def issue_params
      params.require(:issue).permit(:title, :description, :category_id, :tweet_id)
    end
  end
end
