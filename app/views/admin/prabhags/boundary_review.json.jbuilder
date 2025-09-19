# Admin boundary review format
json.boundaries @boundaries_for_review do |boundary|
  json.id boundary.id
  json.status boundary.status
  json.source_type boundary.source_type
  json.year boundary.year
  json.created_at boundary.created_at
  json.submitted_by do
    json.id boundary.submitted_by&.id
    json.name boundary.submitted_by&.name
    json.email boundary.submitted_by&.email
  end
  if boundary.geojson.present?
    json.geojson JSON.parse(boundary.geojson)
    json.geojson_feature JSON.parse(boundary.geojson_feature) if boundary.geojson_feature.present?
  end
end

# Include prabhag info for context
json.prabhag do
  json.id @prabhag.id
  json.number @prabhag.number
  json.ward_code @prabhag.ward_code
  json.pdf_url @prabhag.pdf_url
  json.map_image_src @prabhag.map_image_src
end