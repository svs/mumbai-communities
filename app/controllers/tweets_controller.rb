class TweetsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create]
  skip_forgery_protection only: [:create]

  before_action :set_ward

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Ward not found" }, status: :not_found
  end

  def new
  end

  def create
    if params[:tweet_url].present?
      authenticate_user! unless user_signed_in?
      return if performed?
      create_from_url
    elsif params.key?(:tweets)
      create_from_api
    else
      head :bad_request
    end
  end

  private

  def set_ward
    @ward = Ward.all.find { |w| w.to_param == params[:ward_id] } || Ward.find_by!(ward_code: params[:ward_id].upcase)
  end

  def create_from_url
    unless TweetService::TWEET_URL_PATTERN.match?(params[:tweet_url])
      redirect_to news_ward_path(@ward), alert: "Invalid tweet URL. Please use a twitter.com or x.com status URL."
      return
    end

    TweetService.import_from_url(@ward, params[:tweet_url])
    redirect_to news_ward_path(@ward), notice: "Tweet submitted successfully!"
  rescue => e
    redirect_to news_ward_path(@ward), alert: "Could not import tweet: #{e.message}"
  end

  def create_from_api
    authenticate_api_key!
    return if performed?

    tweets = TweetService.import(@ward, Array(params[:tweets]))
    render json: { imported: tweets.size, tweets: tweets.map { |t| { id: t.tweet_id, body: t.body } } }
  end

  def authenticate_api_key!
    token = request.headers["Authorization"]&.remove("Bearer ")
    head :unauthorized unless token.present? && ActiveSupport::SecurityUtils.secure_compare(token, ENV.fetch("TWEETS_API_KEY"))
  end
end
