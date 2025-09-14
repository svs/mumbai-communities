# Collect all ward features for the index (wards only, no prabhags)
all_features = []

@wards.each do |ward|
  ward_boundary = ward.approved_boundary
  if ward_boundary
    feature = JSON.parse(ward_boundary.geojson_feature)
    # Calculate ward status for styling
    percentage = ward.boundary_mapping_percentage || 0
    activity_status = percentage == 100 ? 'active' : percentage > 0 ? 'growing' : 'inactive'

    # Embed all rendering information in properties
    feature['properties'].merge!({
      'type' => 'ward',
      'ward_code' => ward.ward_code,
      'name' => ward.name,
      'short_name' => ward.short_name,
      'activity_status' => activity_status,
      'boundary_mapping_percentage' => percentage,
      'color' => case activity_status
                when 'active' then '#22c55e'
                when 'growing' then '#eab308'
                else '#3b82f6'
                end,
      'fillOpacity' => case activity_status
                       when 'active' then 0.3
                       when 'growing' then 0.25
                       else 0.0
                       end,
      'weight' => 1,
      'popup_title' => "Ward #{ward.ward_code}",
      'popup_subtitle' => ward.name || 'Mumbai Ward',
      'popup_details' => "#{percentage}% mapped"
    })

    all_features << feature
  end
end

# Return the features array
json.features all_features