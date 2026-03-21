class ParallelClient
  BASE_URL = "https://api.parallel.ai"

  def initialize(api_key: nil)
    @api_key = api_key || Rails.application.credentials.parallels_api_key
    raise "Parallel API key not configured" unless @api_key.present?
  end

  # Quick web search
  def search(objective:, queries:, max_chars: 3000)
    post("/v1beta/search", {
      objective: objective,
      search_queries: queries,
      mode: "fast",
      excerpts: { max_chars_per_result: max_chars }
    })
  end

  # Extract content from URLs
  def extract(urls:, objective:)
    post("/v1beta/extract", {
      urls: urls,
      objective: objective,
      excerpts: true,
      full_content: true
    })
  end

  # Task API — agent-based research with structured output
  def task(input:, output_schema: nil, processor: "base")
    body = { input: input, processor: processor }

    if output_schema.is_a?(String)
      body[:task_spec] = { output_schema: output_schema }
    elsif output_schema.is_a?(Hash)
      body[:task_spec] = {
        output_schema: {
          type: "json",
          json_schema: output_schema
        }
      }
    end

    result = post("/v1/tasks/runs", body)
    run_id = result&.dig("run_id")
    return result unless run_id

    # Poll for completion
    poll_task(run_id)
  end

  private

  def post(path, body)
    uri = URI("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 60

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["x-api-key"] = @api_key
    request.body = body.to_json

    response = http.request(request)
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "Parallel API error: #{e.message}"
    { "error" => e.message }
  end

  def get(path)
    uri = URI("#{BASE_URL}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    request = Net::HTTP::Get.new(uri)
    request["x-api-key"] = @api_key

    response = http.request(request)
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "Parallel API error: #{e.message}"
    { "error" => e.message }
  end

  def poll_task(run_id, timeout: 300)
    deadline = Time.current + timeout
    while Time.current < deadline
      result = get("/v1/tasks/runs/#{run_id}")
      status = result["status"]

      return result if status == "completed" || status == "failed"
      sleep 3
    end
    { "error" => "Task timed out after #{timeout}s", "run_id" => run_id }
  end
end
