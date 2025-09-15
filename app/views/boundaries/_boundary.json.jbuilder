# Reusable partial for rendering a boundary as a GeoJSON Feature
# Usage: json.partial! 'boundaries/boundary', boundary: some_boundary, context: 'review'|'edit'

if boundary&.geojson.present?
  feature = JSON.parse(boundary.geojson_feature)

  # Determine colors based on boundary status and source type
  colors = case boundary.status
           when 'pending'
             { border: '#ef4444', fill: '#fecaca' }
           when 'approved'
             { border: '#059669', fill: '#10b981' }
           when 'canonical'
             { border: '#16a34a', fill: '#22c55e' }
           else
             { border: '#6b7280', fill: '#9ca3af' }
           end

  # Generate boundary label
  boundary_label = case boundary.status
                   when 'pending'
                     'Pending Review'
                   when 'approved'
                     'Approved Boundary'
                   when 'canonical'
                     'Canonical Boundary'
                   else
                     boundary.status.humanize
                   end

  # Context-specific styling
  context = local_assigns[:context] || 'review'
  case context
  when 'edit'
    fill_opacity = 0.4
    popup_subtitle = boundary_label
    popup_details = "#{boundary.source_type.humanize} • #{boundary.created_at.strftime('%b %d, %Y')}"
  else # 'review' context
    fill_opacity = 0.3
    popup_subtitle = "Submitted by #{boundary.submitted_by&.name || 'Unknown User'}"
    popup_details = "#{boundary.status.humanize} • #{boundary.created_at.strftime('%b %d, %Y')}"
  end

  # Create proper GeoJSON Feature structure
  json.type "Feature"
  json.properties do
    json.boundary_id boundary.id
    json.created boundary.created_at
    json.type 'boundary'
    json.status boundary.status
    json.source_type boundary.source_type
    json.color colors[:border]
    json.fillColor colors[:fill]
    json.fillOpacity fill_opacity
    json.weight 2
    json.popup_title "Boundary Submission ##{boundary.id}"
    json.popup_subtitle popup_subtitle
    json.popup_details popup_details
  end
  json.geometry feature['geometry']
end