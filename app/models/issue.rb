class Issue < ApplicationRecord
  include Discussable

  MODEL = "google/gemini-3.1-flash-lite"

  belongs_to :ward, foreign_key: :ward_code, primary_key: :ward_code
  belongs_to :created_by, class_name: "User"
  belongs_to :category, optional: true
  belongs_to :tweet, optional: true

  has_many :todo_items, dependent: :destroy

  validates :title, presence: true
  validates :description, presence: true
  validates :status, inclusion: { in: %w[open in_progress resolved closed] }

  scope :open, -> { where(status: "open") }
  scope :closed, -> { where(status: "closed") }
  scope :recent, -> { order(created_at: :desc) }

  def self.from_tweet(tweet)
    prefill = generate_from_tweet(tweet)
    category = Category.find_by(slug: tweet.category)

    new(
      tweet: tweet,
      ward_code: tweet.ward.ward_code,
      title: prefill[:title],
      description: prefill[:description],
      category: category,
      status: "open"
    )
  end

  def open?
    status == "open"
  end

  def closed?
    status == "closed"
  end

  def close!
    update!(status: "closed")
  end

  def reopen!
    update!(status: "open")
  end

  private_class_method def self.generate_from_tweet(tweet)
    prompt = <<~PROMPT
      You are helping create a civic issue report from a tweet about a Mumbai municipal problem.

      Given this tweet, generate:
      1. A short, clear title (max 80 chars) summarizing the civic issue. Remove @mentions, hashtags, and noise. Write in English even if the tweet is in another language.
      2. A clear description (2-3 sentences) explaining the issue, location if mentioned, and what needs to be done. Write in English.

      Return JSON only: {"title": "...", "description": "..."}

      Tweet:
    PROMPT

    chat = RubyLLM.chat(model: MODEL, provider: :openrouter)
    response = chat.ask(prompt + tweet.body)

    text = response.content.gsub(/\A```json\s*/, "").gsub(/\s*```\z/, "")
    result = JSON.parse(text)

    { title: result["title"].truncate(255), description: result["description"] }
  rescue StandardError => e
    Rails.logger.error "Issue.from_tweet: #{e.message}"
    clean_body = tweet.body.gsub(/@\w+/, "").strip
    { title: clean_body.truncate(80), description: tweet.body }
  end
end
