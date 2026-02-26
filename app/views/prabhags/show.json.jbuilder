# Prabhag show JSON — boundary polygon + ward context + POI markers
json.features do

  # 1. Ward boundary (lighter, for context)
  if @ward&.boundary&.geojson.present?
    ward_boundary = @ward.boundary
    ward_feature = JSON.parse(ward_boundary.geojson_feature) rescue nil
    if ward_feature
      ward_feature['properties'] ||= {}
      ward_feature['properties'].merge!({
        'type' => 'ward',
        'ward_code' => @ward.ward_code,
        'color' => '#3b82f6',
        'fillColor' => '#93c5fd',
        'fillOpacity' => 0.10,
        'weight' => 2,
        'short_name' => @ward.ward_code,
        'popup_title' => "Ward #{@ward.ward_code}",
        'popup_subtitle' => @ward.name
      })
      json.child! { json.merge! ward_feature }
    end
  end

  # 2. Prabhag boundary (main feature)
  json.partial! 'prabhags/prabhag', prabhag: @prabhag, boundary: @prabhag.boundary

  # 3. Markers — live POIs or stored ward facilities
  poi_colors = {
    "hospital" => "#ef4444", "school" => "#3b82f6", "college" => "#3b82f6",
    "toilet" => "#a855f7", "park" => "#22c55e", "garden" => "#22c55e",
    "police" => "#1e3a5f", "fire_station" => "#f97316", "library" => "#8b5cf6",
    "place_of_worship" => "#eab308", "pharmacy" => "#14b8a6", "bank" => "#6366f1",
    "post_office" => "#f59e0b", "playground" => "#10b981", "bus_station" => "#64748b",
    "railway_station" => "#475569"
  }

  if @pois.present?
    @pois.each do |poi|
      next unless poi[:lat] && poi[:lng]
      color = poi_colors[poi[:type].to_s] || "#6b7280"
      json.child! do
        json.type "Feature"
        json.geometry do
          json.type "Point"
          json.coordinates [poi[:lng], poi[:lat]]
        end
        json.properties do
          json.type "poi"
          json.poi_type poi[:type]
          json.name poi[:name].presence || "Unnamed #{poi[:type].to_s.humanize.downcase}"
          json.marker_color color
          json.popup_title poi[:name].presence || poi[:type].to_s.humanize
          json.popup_subtitle poi[:type].to_s.humanize
        end
      end
    end
  elsif @prabhag_facilities.present?
    @prabhag_facilities.each do |facility|
      color = poi_colors[facility.facility_type] || "#6b7280"
      json.child! do
        json.type "Feature"
        json.geometry do
          json.type "Point"
          json.coordinates [facility.longitude, facility.latitude]
        end
        json.properties do
          json.type "facility"
          json.facility_id facility.id
          json.poi_type facility.facility_type
          json.name facility.name || "Unnamed #{facility.facility_type.humanize.downcase}"
          json.marker_color color
          json.popup_title facility.name || facility.facility_type.humanize
          json.popup_subtitle facility.facility_type.humanize
          json.source facility.source
        end
      end
    end
  end
end
