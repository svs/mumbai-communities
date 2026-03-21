class WardEnrichmentJob < ApplicationJob
  queue_as :default

  OFFICER_SCHEMA = {
    type: "object",
    properties: {
      ward_code: { type: "string" },
      officers: {
        type: "array",
        items: {
          type: "object",
          properties: {
            designation: { type: "string", description: "Official title e.g. Assistant Commissioner, Executive Engineer, Medical Officer of Health" },
            person_name: { type: "string", description: "Full name with honorific (Shri./Smt./Dr.)" },
            phone: { type: "string", description: "10-digit mobile number" },
            email: { type: "string", description: "Official @mcgm.gov.in email address" },
            section: { type: "string", description: "Department: Ward Office, Maintenance, Water Works, Solid Waste Management, Building and Factory, Health, Gardens, Education, Licence, Assessment and Collection" },
            level: { type: "string", enum: %w[senior mid junior], description: "AC/EE/DO/MOH = senior, AE/AO/Inspector = mid, SE/JE/Clerk = junior" }
          }
        }
      }
    }
  }.freeze

  def perform(ward_code = nil)
    client = ParallelClient.new

    wards = if ward_code
      [Ward.find_by!(ward_code: ward_code)]
    else
      Ward.order(:ward_code).all
    end

    wards.each do |ward|
      Rails.logger.info "Enriching Ward #{ward.ward_code}..."
      enrich_ward(ward, client)
      sleep 3 unless ward == wards.last
    end
  end

  private

  def enrich_ward(ward, client)
    # Step 1: Search for ward contact list
    results = client.search(
      objective: "Find the official MCGM/BMC ward office contact list for #{ward.ward_code} Ward Mumbai with all officer names, designations, phone numbers, and email addresses",
      queries: [
        "site:mcgm.gov.in #{ward.ward_code} ward important numbers contact officers",
        "site:dm.mcgm.gov.in #{ward.ward_code} ward",
        "BMC #{ward.ward_code} ward Mumbai officers contact list 2025"
      ],
      max_chars: 5000
    )

    if results.is_a?(Hash) && results["error"]
      Rails.logger.error "Ward #{ward.ward_code}: Search error: #{results['error']}"
      return
    end

    results = results["results"] if results.is_a?(Hash)
    return unless results.is_a?(Array)

    # Step 2: Extract officer data from search results
    officers = parse_officers_from_results(results)

    # Step 3: If we found a PDF URL, try extracting from it directly
    if officers.count < 5
      pdf_url = results.find { |r| r["url"]&.match?(/mcgm.*\.pdf/i) }&.dig("url")
      if pdf_url
        Rails.logger.info "  Extracting from PDF: #{pdf_url}"
        extract_results = client.extract(urls: [pdf_url], objective: "Extract all officer names, designations, phone numbers, and email addresses")
        if extract_results.is_a?(Hash) && extract_results["results"]
          all_content = extract_results["results"].flat_map { |r|
            [r["full_content"], *(r["excerpts"] || [])]
          }.compact.join("\n\n")
          officers += parse_with_llm(all_content) if all_content.present?
        end
      end
    end

    officers.uniq! { |o| [o[:designation], o[:person_name]] }

    if officers.empty?
      Rails.logger.warn "Ward #{ward.ward_code}: No officers found"
      return
    end

    import_officers(ward, officers)
  end

  LLM_MODEL = "google/gemini-2.0-flash-001"

  def parse_officers_from_results(results)
    # Collect all text content from search results
    all_content = results.flat_map { |r| r["excerpts"] || [] }.join("\n\n")
    return [] if all_content.blank?

    # Use LLM to extract structured data
    parse_with_llm(all_content)
  end

  def parse_with_llm(content)
    prompt = <<~PROMPT
      Extract all BMC ward officers from this text. Return ONLY a JSON array.

      For each officer, extract:
      - designation: their title (e.g. "Assistant Commissioner", "Executive Engineer", "AE (Maintenance)")
      - person_name: full name with honorific (e.g. "Shri. Sharad Ughade")
      - phone: 10-digit mobile number
      - email: email address
      - section: department (Ward Office, Maintenance, Water Works, Solid Waste Management, Building and Factory, Health, Gardens, Education, Licence, Assessment and Collection)
      - level: "senior" for AC/EE/DO/MOH, "mid" for AE/AO/Inspector, "junior" for SE/JE/Clerk

      Only include officers with actual names. Skip headers, addresses, and ward info.
      Return valid JSON only — no markdown, no explanation.

      Text:
      #{content.truncate(8000)}
    PROMPT

    chat = RubyLLM.chat(model: LLM_MODEL, provider: :openrouter)
    response = chat.ask(prompt)
    text = response.content.gsub(/\A```json\s*/m, "").gsub(/\s*```\z/m, "").strip

    officers = JSON.parse(text)
    officers = officers["officers"] if officers.is_a?(Hash) && officers["officers"]

    officers.map do |o|
      {
        designation: o["designation"],
        person_name: o["person_name"],
        phone: o["phone"],
        email: o["email"],
        section: o["section"] || "Ward Office",
        level: o["level"] || guess_level(o["designation"] || "")
      }
    end
  rescue JSON::ParserError => e
    Rails.logger.error "LLM parse error: #{e.message}"
    []
  rescue => e
    Rails.logger.error "LLM error: #{e.message}"
    []
  end

  def import_officers(ward, officers)
    org = Organisation.find_or_create_by!(organisable: ward, org_type: "ward_office") do |o|
      o.name = "Ward #{ward.ward_code}"
    end

    imported = 0
    updated = 0
    transferred = 0

    officers.each do |officer|
      officer = officer.with_indifferent_access
      next unless officer[:designation].present?

      # Find or create person
      person = nil
      if officer[:person_name].present?
        person = Person.find_or_create_by!(name: officer[:person_name]) do |p|
          p.phone = officer[:phone]
        end
        person.update!(phone: officer[:phone]) if officer[:phone].present? && person.phone.blank?
      end

      section = officer[:section].presence || "Ward Office"
      level = officer[:level].presence || guess_level(officer[:designation])

      # Find existing active position by email or designation+section
      existing = nil
      if officer[:email].present?
        existing = org.positions.find_by(email: officer[:email], active: true)
      end
      existing ||= org.positions.find_by(designation: officer[:designation], section: section, active: true)

      if existing
        if existing.person_id == person&.id || person.nil?
          # Same person or unknown — update
          attrs = {}
          attrs[:person] = person if person && existing.person_id.nil?
          attrs[:phone] = officer[:phone] if officer[:phone].present?
          attrs[:email] = officer[:email] if officer[:email].present? && existing.email.blank?
          attrs[:level] = level if existing.level.blank?
          existing.update!(attrs) if attrs.any?
          updated += 1
        else
          # Transfer!
          Rails.logger.info "  TRANSFER: #{existing.designation} #{existing.person&.name} -> #{person&.name}"
          existing.update!(active: false, ended_on: Date.current)
          org.positions.create!(
            designation: officer[:designation],
            person: person,
            phone: officer[:phone],
            email: officer[:email],
            section: section,
            level: level,
            active: true,
            started_on: Date.current
          )
          transferred += 1
        end
      else
        org.positions.create!(
          designation: officer[:designation],
          person: person,
          phone: officer[:phone],
          email: officer[:email],
          section: section,
          level: level,
          active: true,
          started_on: Date.current
        )
        imported += 1
      end
    end

    Rails.logger.info "Ward #{ward.ward_code}: #{imported} new, #{updated} updated, #{transferred} transfers"
  end

  def guess_level(designation)
    case designation
    when /Commissioner|Executive Engineer|Designated Officer|Medical Officer/i
      "senior"
    when /Assistant Engineer|Administrative Officer|Inspector|Assessor|Complaint|Supdt/i
      "mid"
    else
      "junior"
    end
  end
end
