require "net/http"
require "json"
require "uri"

namespace :officers do
  desc "Enrich ward officers using Parallel AI (all wards or specify WARD=A)"
  task enrich: :environment do
    api_key = Rails.application.credentials.parallels_api_key
    abort "ERROR: parallels_api_key not in credentials" unless api_key.present?

    ward_code = ENV["WARD"]
    wards = if ward_code
      [Ward.find_by!(ward_code: ward_code)]
    else
      Ward.order(:ward_code).all
    end

    wards.each do |ward|
      puts "\n=== Ward #{ward.ward_code} ==="
      process_ward(ward, api_key)
      sleep 2 unless ward == wards.last
    end
  end

  desc "Enrich officer profiles with news and social links (WARD=A or all)"
  task enrich_profiles: :environment do
    api_key = Rails.application.credentials.parallels_api_key
    abort "ERROR: parallels_api_key not in credentials" unless api_key.present?

    ward_code = ENV["WARD"]
    wards = if ward_code
      [Ward.find_by!(ward_code: ward_code)]
    else
      Ward.order(:ward_code).all
    end

    wards.each do |ward|
      org = ward.organisation
      next unless org

      positions = Position.joins(department: :organisation)
        .where(organisations: { organisable: ward }, active: true)
        .where.not(person_name: [nil, ""])
        .where(level: "senior")

      positions.each do |pos|
        next if pos.profile_data.present? && pos.profile_data["enriched_at"].present?

        puts "  Enriching: #{pos.person_name} (#{pos.designation}, Ward #{ward.ward_code})"
        enrich_profile(pos, ward, api_key)
        sleep 2
      end
    end
  end

  def process_ward(ward, api_key)
    # Step 1: Search for ward contact list
    contact_url = find_contact_url(ward, api_key)

    if contact_url
      puts "  Found contact URL: #{contact_url}"
      # Step 2: Extract officer data
      officers = extract_officers(contact_url, api_key)
      sleep 2
    else
      puts "  No contact PDF found, trying search-based extraction..."
      officers = search_officers(ward, api_key)
    end

    if officers.empty?
      puts "  No officers found"
      return
    end

    # Step 3: Import
    import_officers(ward, officers)
  end

  def find_contact_url(ward, api_key)
    # Try known URL patterns first
    known_patterns = [
      "https://portal.mcgm.gov.in/irj/go/km/docs/documents/#{URI.encode_www_form_component(ward.ward_code + ' Ward')}/Important%20Numbers.pdf",
      "https://portal.mcgm.gov.in/irj/go/km/docs/documents/#{URI.encode_www_form_component(ward.ward_code)}/Important%20Numbers.pdf"
    ]

    # Search Parallel for the contact PDF
    results = parallel_search(api_key,
      objective: "Find the official MCGM/BMC ward office contact list with officer names and phone numbers for #{ward.ward_code} Ward Mumbai",
      queries: [
        "site:mcgm.gov.in #{ward.ward_code} ward important numbers contact officers",
        "site:portal.mcgm.gov.in #{ward.ward_code} ward officers phone"
      ]
    )

    # Look for PDF URLs in results
    results.each do |r|
      url = r["url"]
      if url&.match?(/mcgm\.gov\.in.*\.(pdf|PDF)/i) ||
         url&.match?(/Important.*Numbers/i)
        return url
      end
    end

    nil
  end

  def extract_officers(url, api_key)
    data = parallel_extract(api_key,
      urls: [url],
      objective: "Extract all officer names, designations, phone numbers, and email addresses from this BMC ward contact list"
    )

    return [] if data.empty?

    # Parse the markdown content into officer records
    content = data.first&.dig("full_content") || data.first&.dig("excerpts")&.join("\n") || ""
    parse_officer_content(content)
  end

  def search_officers(ward, api_key)
    results = parallel_search(api_key,
      objective: "Find the complete list of current officers of BMC #{ward.ward_code} Ward Mumbai with their names, designations, and phone numbers",
      queries: [
        "BMC #{ward.ward_code} ward Mumbai officers contact list 2025",
        "MCGM #{ward.ward_code} ward assistant commissioner designated officer"
      ],
      max_chars: 5000
    )

    officers = []
    results.each do |r|
      (r["excerpts"] || []).each do |excerpt|
        officers += parse_officer_content(excerpt)
      end
    end

    officers.uniq { |o| [o[:designation], o[:person_name]] }
  end

  def parse_officer_content(content)
    officers = []
    lines = content.split("\n").map(&:strip).reject(&:empty?)

    designation_map = {
      /Asst\.?\s*Commissioner/i => { designation: "Assistant Commissioner", section: "Ward Office", level: "senior" },
      /Executive\s*Engineer/i => { designation: "Executive Engineer", section: "Ward Office", level: "senior" },
      /Designated\s*Officer/i => { designation: "Designated Officer", section: "Ward Office", level: "senior" },
      /Medical\s*Officer.*Health|MOH/i => { designation: "Medical Officer of Health", section: "Health", level: "senior" },
      /Complaint\s*Officer/i => { designation: "Complaint Officer", section: "Ward Office", level: "mid" },
      /A\.?E\.?\s*\(?Maint.*East/i => { designation: "Assistant Engineer (Maintenance East)", section: "Maintenance", level: "mid" },
      /A\.?E\.?\s*\(?Maint.*West/i => { designation: "Assistant Engineer (Maintenance West)", section: "Maintenance", level: "mid" },
      /A\.?E\.?\s*\(?Maint/i => { designation: "Assistant Engineer (Maintenance)", section: "Maintenance", level: "mid" },
      /A\.?E\.?\s*\(?SWM/i => { designation: "Assistant Engineer (SWM)", section: "Solid Waste Management", level: "mid" },
      /A\.?E\.?\s*\(?B\s*&?\s*F/i => { designation: "Assistant Engineer (B&F)", section: "Building and Factory", level: "mid" },
      /A\.?E\.?\s*\(?Water/i => { designation: "Assistant Engineer (Water)", section: "Water Works", level: "mid" },
      /Sr\.?\s*Insp.*Licence/i => { designation: "Sr. Inspector (Licence)", section: "Licence", level: "mid" },
      /Sr\.?\s*Insp.*Ench/i => { designation: "Sr. Inspector (Encroachment)", section: "Licence", level: "mid" },
      /AA\s*&?\s*C|Asst.*Assessor/i => { designation: "Asst. Assessor & Collector", section: "Assessment and Collection", level: "mid" },
      /PCO|Pest\s*Control/i => { designation: "Pest Control Officer", section: "Health", level: "mid" },
      /ASG|Asst.*Supdt.*Garden/i => { designation: "Asst. Supdt. of Garden", section: "Gardens", level: "mid" },
      /A\.?O\.?\s*\(?School/i => { designation: "Administrative Officer (School)", section: "Education", level: "mid" },
      /Colony\s*Officer/i => { designation: "Colony Officer", section: "Estate", level: "mid" },
    }

    i = 0
    while i < lines.length
      line = lines[i]

      # Try to match designation
      matched = nil
      designation_map.each do |pattern, info|
        if line.match?(pattern)
          matched = info
          break
        end
      end

      if matched
        # Look for name in same line or surrounding lines
        name = nil
        phone = nil
        email = nil

        # Check for name on same line (often: "Designation\nName\nPhone")
        # Or name might be embedded: "Shri Sharad Ughade 9167494033"
        name_match = line.match(/((?:Shri\.?|Smt\.?|Dr\.?\s*(?:\((?:Shri|Smt)\.\?)?\s*)\s*[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)/i)
        if name_match
          name = name_match[1].strip
        end

        # Check surrounding lines for name, phone, email
        (-2..4).each do |offset|
          next if offset == 0
          check_line = lines[i + offset]&.strip
          next unless check_line

          # Phone: 10 digit number
          if phone.nil?
            phone_match = check_line.match(/(\d{10})/)
            phone = phone_match[1] if phone_match
          end

          # Email
          if email.nil?
            email_match = check_line.match(/([a-zA-Z0-9._]+@[a-zA-Z0-9._]+\.[a-zA-Z]+)/)
            email = email_match[1] if email_match
          end

          # Name (if not found yet)
          if name.nil?
            name_match = check_line.match(/^((?:Shri\.?|Smt\.?|Dr\.?\s*(?:\((?:Shri|Smt)\.\?)?\s*)\s*[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)/i)
            name = name_match[1].strip if name_match
          end
        end

        # Also check same line for phone
        phone_match = line.match(/(\d{10})/)
        phone ||= phone_match[1] if phone_match

        officers << {
          designation: matched[:designation],
          section: matched[:section],
          level: matched[:level],
          person_name: name,
          phone: phone,
          email: email
        }
      end

      i += 1
    end

    officers
  end

  def import_officers(ward, officers)
    ward_org = Organisation.find_or_create_by!(organisable: ward, org_type: "ward") do |org|
      org.name = "Ward #{ward.ward_code}"
    end

    imported = 0
    updated = 0
    transferred = 0

    officers.each do |officer|
      next unless officer[:designation].present?

      dept = Department.find_or_create_by!(organisation: ward_org, name: officer[:section])

      # Find existing active position
      existing = nil
      if officer[:email].present?
        existing = Position.joins(:department)
          .where(departments: { organisation_id: ward_org.id })
          .where(email: officer[:email], active: true)
          .first
      end
      existing ||= Position.where(department: dept, designation: officer[:designation], active: true).first

      if existing
        if existing.person_name == officer[:person_name] || officer[:person_name].nil?
          # Same person or no name — update contact info
          attrs = {}
          attrs[:phone] = officer[:phone] if officer[:phone].present?
          attrs[:email] = officer[:email] if officer[:email].present? && existing.email.blank?
          attrs[:person_name] = officer[:person_name] if officer[:person_name].present? && existing.person_name.blank?
          existing.update!(attrs) if attrs.any?
          updated += 1
        else
          # Transfer detected!
          puts "  TRANSFER: #{existing.designation} #{existing.person_name} -> #{officer[:person_name]}"
          existing.update!(active: false, ended_on: Date.current)
          Position.create!(
            department: dept,
            designation: officer[:designation],
            person_name: officer[:person_name],
            phone: officer[:phone],
            email: officer[:email],
            level: officer[:level],
            active: true,
            started_on: Date.current
          )
          transferred += 1
        end
      else
        Position.create!(
          department: dept,
          designation: officer[:designation],
          person_name: officer[:person_name],
          phone: officer[:phone],
          email: officer[:email],
          level: officer[:level],
          active: true,
          started_on: Date.current
        )
        imported += 1
      end
    end

    puts "  Ward #{ward.ward_code}: #{imported} new, #{updated} updated, #{transferred} transfers"
  end

  def enrich_profile(position, ward, api_key)
    results = parallel_search(api_key,
      objective: "Find news articles, LinkedIn profile, and Twitter handle for #{position.person_name}, #{position.designation} of #{ward.ward_code} Ward BMC Mumbai",
      queries: [
        "#{position.person_name} BMC Mumbai #{ward.ward_code} ward",
        "#{position.person_name} MCGM linkedin"
      ],
      max_chars: 2000
    )

    linkedin_url = nil
    news = []

    results.each do |r|
      url = r["url"]

      # LinkedIn
      if url&.include?("linkedin.com/in/")
        linkedin_url = url
      end

      # News articles
      if url&.match?(/hindustantimes|timesofindia|freepressjournal|mumbaimirror|ndtv|indianexpress|mid-day/i)
        news << {
          "title" => r["title"]&.truncate(120),
          "url" => url,
          "source" => URI.parse(url).host.gsub(/^www\./, "").split(".").first.capitalize,
          "excerpt" => r["excerpts"]&.first&.truncate(200)
        }
      end
    end

    attrs = {}
    attrs[:linkedin_url] = linkedin_url if linkedin_url.present?
    attrs[:profile_data] = {
      "news" => news.first(5),
      "enriched_at" => Time.current.iso8601,
      "source" => "Parallel AI search"
    }

    position.update!(attrs)
    puts "    -> LinkedIn: #{linkedin_url ? 'found' : 'no'}, News: #{news.count} articles"
  end

  # --- Parallel API helpers ---

  def parallel_search(api_key, objective:, queries:, max_chars: 3000)
    body = {
      objective: objective,
      search_queries: queries,
      mode: "fast",
      excerpts: { max_chars_per_result: max_chars }
    }

    response = parallel_request("/v1beta/search", api_key, body)
    response&.dig("results") || []
  end

  def parallel_extract(api_key, urls:, objective:)
    body = {
      urls: urls,
      objective: objective,
      excerpts: true,
      full_content: true
    }

    response = parallel_request("/v1beta/extract", api_key, body)
    response&.dig("results") || []
  end

  def parallel_request(path, api_key, body)
    uri = URI("https://api.parallel.ai#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["x-api-key"] = api_key
    request.body = body.to_json

    response = http.request(request)

    if response.code.to_i == 200
      JSON.parse(response.body)
    else
      puts "  API error (#{response.code}): #{response.body.truncate(200)}"
      nil
    end
  rescue => e
    puts "  Request error: #{e.message}"
    nil
  end
end
