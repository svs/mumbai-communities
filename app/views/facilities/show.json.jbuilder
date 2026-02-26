poi_colors = {
  "hospital" => "#ef4444", "school" => "#3b82f6", "college" => "#3b82f6",
  "toilet" => "#a855f7", "park" => "#22c55e", "garden" => "#22c55e",
  "police" => "#1e3a5f", "fire_station" => "#f97316", "library" => "#8b5cf6",
  "place_of_worship" => "#eab308", "pharmacy" => "#14b8a6", "bank" => "#6366f1",
  "post_office" => "#f59e0b", "playground" => "#10b981", "bus_station" => "#64748b",
  "railway_station" => "#475569"
}

json.features do
  # Prabhag boundary for context (if available)
  if @prabhag&.boundary&.geojson.present?
    json.partial! 'prabhags/prabhag', prabhag: @prabhag, boundary: @prabhag.boundary
  end

  # The facility marker
  if @facility.latitude && @facility.longitude
    color = poi_colors[@facility.facility_type] || "#6b7280"
    json.child! do
      json.type "Feature"
      json.geometry do
        json.type "Point"
        json.coordinates [@facility.longitude, @facility.latitude]
      end
      json.properties do
        json.type "facility"
        json.poi_type @facility.facility_type
        json.name @facility.name || "Unnamed #{@facility.facility_type.humanize}"
        json.marker_color color
        json.popup_title @facility.name || @facility.facility_type.humanize
        json.popup_subtitle @facility.facility_type.humanize
      end
    end
  end
end
