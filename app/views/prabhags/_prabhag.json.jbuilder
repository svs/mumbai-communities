# Reusable partial for rendering a prabhag boundary as a GeoJSON Feature
# Usage: json.partial! 'prabhags/prabhag', prabhag: some_prabhag, boundary: some_boundary, context: 'show'|'ward'

boundary = boundary || prabhag.approved_boundary
if boundary&.geojson.present?
  feature = JSON.parse(boundary.geojson_feature)

  # Determine colors based on boundary type and status (consistent with ward show page)
  colors = case boundary.source_type
           when 'kml_import'
             boundary.status == 'approved' ? { border: '#f59e0b', fill: '#fbbf24' } : { border: '#6b7280', fill: '#9ca3af' }
           when 'official_import'
             if boundary.status == 'canonical'
               { border: '#16a34a', fill: '#22c55e' }
             elsif boundary.status == 'approved'
               { border: '#059669', fill: '#10b981' }
             else
               { border: '#6b7280', fill: '#9ca3af' }
             end
           when 'user_submission'
             boundary.status == 'approved' ? { border: '#8b5cf6', fill: '#a78bfa' } : { border: '#6b7280', fill: '#9ca3af' }
           else
             { border: '#6b7280', fill: '#9ca3af' }
           end

  # Generate boundary label for detailed contexts
  boundary_label = case boundary.source_type
                   when 'kml_import'
                     boundary.status == 'approved' ? 'Legacy boundary' : 'Unknown'
                   when 'official_import'
                     if boundary.status == 'canonical'
                       'Official (canonical)'
                     elsif boundary.status == 'approved'
                       'Official (approved)'
                     else
                       "#{boundary.source_type} (#{boundary.status})"
                     end
                   when 'user_submission'
                     boundary.status == 'approved' ? 'Community mapped' : "#{boundary.source_type} (#{boundary.status})"
                   else
                     "#{boundary.source_type} (#{boundary.status})"
                   end

  # Context-specific styling
  context = local_assigns[:context] || 'show'
  case context
  when 'ward'
    fill_opacity = 0.2
    popup_subtitle = boundary_label
    popup_details = "#{boundary.source_type} (#{boundary.year || 'Historical'})"
  else # 'show' context
    fill_opacity = 0.35
    popup_subtitle = "Ward #{prabhag.ward_code}"
    popup_details = "#{boundary.source_type.humanize}, #{boundary.status.humanize}"
  end

  # Embed all rendering information in properties
  feature['properties'].merge!({
    'type' => 'prabhag',
    'prabhag_number' => prabhag.number,
    'prabhag_id' => prabhag.id,
    'ward_code' => prabhag.ward_code,
    'status' => boundary.status,
    'source_type' => boundary.source_type,
    'color' => colors[:border],
    'fillColor' => colors[:fill],
    'fillOpacity' => fill_opacity,
    'weight' => 1,
    'short_name' => "P#{prabhag.number}",
    'popup_title' => "Prabhag #{prabhag.number}",
    'popup_subtitle' => popup_subtitle,
    'popup_details' => popup_details
  })

  json.child! do
    json.merge! feature
  end
end