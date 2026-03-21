class PersonEnrichmentJob < ApplicationJob
  queue_as :default

  LLM_MODEL = "google/gemini-2.0-flash-001"

  def perform(person_id, ward_code = nil)
    person = Person.find_by(id: person_id)
    return unless person
    return if person.profile_data.present? # Already enriched

    client = ParallelClient.new

    ward_context = ward_code ? "#{ward_code} Ward" : ""
    position = person.positions.active.first
    designation = position&.designation || ""

    results = client.search(
      objective: "Find news articles, public references, and background information about #{person.name}, #{designation} of BMC #{ward_context} Mumbai. I want news coverage of their civic duties, any public mentions, and biographical details.",
      queries: [
        "#{person.name} BMC #{ward_context} Mumbai",
        "#{person.name} MCGM Mumbai #{designation}"
      ],
      max_chars: 2000
    )

    results = results["results"] if results.is_a?(Hash)
    return unless results.is_a?(Array)

    news = []
    linkedin_url = nil

    results.each do |r|
      url = r["url"]
      title = r["title"]

      # LinkedIn
      if url&.include?("linkedin.com/in/") && title&.downcase&.include?(person.name.split.last.downcase)
        linkedin_url = url
      end

      # News articles from known sources
      if url&.match?(/hindustantimes|timesofindia|freepressjournal|mumbaimirror|ndtv|indianexpress|mid-day|dnaindia/i)
        excerpt = (r["excerpts"] || []).first&.truncate(200)
        news << {
          "title" => title&.truncate(120),
          "url" => url,
          "source" => URI.parse(url).host.gsub(/^www\./, "").split(".").first.capitalize,
          "excerpt" => excerpt
        }
      end
    end

    # Generate bio from search results using LLM
    bio = generate_bio(person, designation, ward_context, results)

    person.update!(
      bio: bio.presence || person.bio,
      linkedin_url: linkedin_url.presence || person.linkedin_url,
      profile_data: {
        "news" => news.first(5),
        "enriched_at" => Time.current.iso8601,
        "source" => "Parallel AI search"
      }
    )

    Rails.logger.info "Enriched #{person.name}: bio=#{bio.present?}, news=#{news.count}, linkedin=#{linkedin_url.present?}"
  end

  private

  def generate_bio(person, designation, ward_context, results)
    excerpts = results.flat_map { |r| r["excerpts"] || [] }.first(5).join("\n")
    return nil if excerpts.blank?

    prompt = <<~PROMPT
      Write a 2-3 sentence professional bio for #{person.name}, #{designation} of BMC #{ward_context} Mumbai.
      Based on these web search results, summarize their role and any notable public activities.
      Write in third person. Be factual. If there's not enough info, just describe their current role.
      Return ONLY the bio text, no quotes or labels.

      Search results:
      #{excerpts.truncate(3000)}
    PROMPT

    chat = RubyLLM.chat(model: LLM_MODEL, provider: :openrouter)
    response = chat.ask(prompt)
    response.content.strip
  rescue => e
    Rails.logger.error "Bio generation error: #{e.message}"
    nil
  end
end
