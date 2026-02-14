json.type "FeatureCollection"
json.features @facilities do |facility|
  next unless facility.latitude && facility.longitude

  marker_color = case facility.facility_type
                 when "hospital" then "#ef4444"
                 when "school" then "#3b82f6"
                 when "toilet" then "#a855f7"
                 when "park", "garden", "open_space" then "#22c55e"
                 when "police" then "#1e3a5f"
                 when "fire_station" then "#f97316"
                 when "library" then "#8b5cf6"
                 when "place_of_worship" then "#eab308"
                 when "pharmacy" then "#14b8a6"
                 when "bank" then "#6366f1"
                 when "post_office" then "#f59e0b"
                 when "playground" then "#10b981"
                 when "bus_station" then "#64748b"
                 when "railway_station" then "#475569"
                 else "#6b7280"
                 end

  source_label = case facility.source
                 when "bmc_arcgis", "bmc_portal" then "BMC"
                 when "osm" then "OSM"
                 else facility.source.upcase
                 end

  source_badge_class = case facility.source
                       when "bmc_arcgis", "bmc_portal" then "bg-blue-100 text-blue-700"
                       when "osm" then "bg-green-100 text-green-700"
                       else "bg-stone-100 text-stone-700"
                       end

  json.type "Feature"
  json.geometry do
    json.type "Point"
    json.coordinates [facility.longitude, facility.latitude]
  end
  json.properties do
    json.id facility.id
    json.name facility.name || "Unnamed #{facility.facility_type.humanize}"
    json.facility_type facility.facility_type
    json.facility_type_label facility.facility_type.humanize
    json.source facility.source
    json.source_label source_label
    json.source_badge_class source_badge_class
    json.address facility.address
    json.marker_color marker_color
    json.marker_border marker_color
  end
end
