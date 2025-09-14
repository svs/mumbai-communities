class MigrateLegacyBoundaryGeojsonToCanonicalBoundaries < ActiveRecord::Migration[8.0]
  def up
    # Find prabhags with legacy boundary_geojson data
    prabhags_with_legacy = Prabhag.where.not(boundary_geojson: [nil, ''])
    puts "Found #{prabhags_with_legacy.count} prabhags with legacy boundary data"

    boundary_ids_to_canonicalize = []

    prabhags_with_legacy.each do |prabhag|
      # Get the best boundary for this prabhag (should be approved)
      best_boundary = prabhag.boundaries.where(status: 'approved').first
      if best_boundary
        boundary_ids_to_canonicalize << best_boundary.id
        puts "Will mark boundary #{best_boundary.id} as canonical for Prabhag #{prabhag.ward_code}-#{prabhag.number}"
      end
    end

    # Update only these specific boundaries to canonical
    Boundary.where(id: boundary_ids_to_canonicalize).update_all(
      status: 'canonical',
      is_canonical: true,
      updated_at: Time.current
    )

    puts "Marked #{boundary_ids_to_canonicalize.count} boundaries as canonical"
    puts "Migration completed"
  end

  def down
    # Find prabhags with legacy boundary_geojson data and revert their boundaries
    prabhags_with_legacy = Prabhag.where.not(boundary_geojson: [nil, ''])
    boundary_ids_to_revert = []

    prabhags_with_legacy.each do |prabhag|
      canonical_boundary = prabhag.boundaries.where(status: 'canonical', is_canonical: true).first
      if canonical_boundary
        boundary_ids_to_revert << canonical_boundary.id
      end
    end

    puts "Found #{boundary_ids_to_revert.count} canonical boundaries to revert to approved"

    Boundary.where(id: boundary_ids_to_revert).update_all(
      status: 'approved',
      is_canonical: false,
      updated_at: Time.current
    )

    puts "Reverted #{boundary_ids_to_revert.count} boundaries to approved status"
    puts "Rollback completed"
  end
end
