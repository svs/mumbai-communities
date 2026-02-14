class TweetsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_forgery_protection
  before_action :authenticate_api_key!

  def create
    @ward = Ward.all.find { |w| w.to_param == params[:ward_id] } || Ward.find_by!(ward_code: params[:ward_id].upcase)
    tweets = TweetService.import(@ward, Array(params[:tweets]))

    render json: { imported: tweets.size, tweets: tweets.map { |t| { id: t.tweet_id, body: t.body } } }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Ward not found" }, status: :not_found
  end

  private

  def authenticate_api_key!
    token = request.headers["Authorization"]&.remove("Bearer ")
    head :unauthorized unless token.present? && ActiveSupport::SecurityUtils.secure_compare(token, ENV.fetch("TWEETS_API_KEY"))
  end
end
