module TweetsHelper
  def format_tweet_body(body)
    text = body.gsub(%r{https?://t\.co/\w+}, '').strip

    # Linkify @mentions
    text = text.gsub(/@(\w+)/) do
      %(<span class="text-blue-600">@#{$1}</span>)
    end

    # Linkify #hashtags
    text = text.gsub(/#(\w+)/) do
      %(<span class="text-blue-600">##{$1}</span>)
    end

    text.html_safe
  end
end
