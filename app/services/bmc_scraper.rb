require "net/http"
require "uri"

class BmcScraper
  BASE_URL = "https://portal.mcgm.gov.in".freeze
  TIMEOUT_SECONDS = 30

  # Ward page URL patterns on the BMC portal
  WARD_PAGE_PATTERNS = {
    "rti" => "/irj/portal/anonymous/qlacaward?ward_id=%{ward_code}&TabId=rti",
    "docs" => "/irj/portal/anonymous/qlacaward?ward_id=%{ward_code}&TabId=docs",
    "financial" => "/irj/portal/anonymous/qlacaward?ward_id=%{ward_code}&TabId=financial"
  }.freeze

  class << self
    def scrape_all
      results = { scraped: 0, changed: 0, errors: 0 }

      Ward.pluck(:ward_code).each do |ward_code|
        ward_results = scrape_ward(ward_code)
        results[:scraped] += ward_results[:scraped]
        results[:changed] += ward_results[:changed]
        results[:errors] += ward_results[:errors]
      end

      results
    end

    def scrape_ward(ward_code)
      results = { scraped: 0, changed: 0, errors: 0 }

      WARD_PAGE_PATTERNS.each do |data_type, pattern|
        url = BASE_URL + format(pattern, ward_code: URI.encode_www_form_component(ward_code))

        content = fetch_page(url)
        if content.nil?
          results[:errors] += 1
          next
        end

        content_hash = Digest::SHA256.hexdigest(content)
        previous = WardDataSnapshot
          .for_ward(ward_code)
          .of_type(data_type)
          .latest
          .first

        changed = previous.nil? || previous.content_hash != content_hash

        WardDataSnapshot.create!(
          ward_code: ward_code,
          source_url: url,
          data_type: data_type,
          content: content,
          content_hash: content_hash
        )

        results[:scraped] += 1
        results[:changed] += 1 if changed
      end

      results
    end

    private

    def fetch_page(url)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = TIMEOUT_SECONDS
      http.read_timeout = TIMEOUT_SECONDS

      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "WardPress/1.0 (BMC Data Monitor)"

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        response.body
      else
        Rails.logger.warn "BmcScraper: Got #{response.code} for #{url}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "BmcScraper: Error fetching #{url}: #{e.message}"
      nil
    end
  end
end
