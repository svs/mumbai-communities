# We don't clear existing data - we update it to preserve relationships

puts "Seeding categories..."
CATEGORY_DEFINITIONS = [
  { name: "Roads & Footpaths", slug: "roads_and_footpaths", color: "#6b7280", position: 0 },
  { name: "Water & Sewerage", slug: "water_and_sewerage", color: "#3b82f6", position: 1 },
  { name: "Solid Waste Management", slug: "solid_waste_management", color: "#22c55e", position: 2 },
  { name: "Public Health", slug: "public_health", color: "#ef4444", position: 3 },
  { name: "Encroachment", slug: "encroachment", color: "#f59e0b", position: 4 },
  { name: "Transport & Mobility", slug: "transport_and_mobility", color: "#8b5cf6", position: 5 },
  { name: "Environment", slug: "environment", color: "#10b981", position: 6 },
  { name: "Housing & Building", slug: "housing_and_building", color: "#f97316", position: 7 },
  { name: "Public Safety", slug: "public_safety", color: "#dc2626", position: 8 },
  { name: "Utilities", slug: "utilities", color: "#6366f1", position: 9 },
  { name: "Parks & Open Spaces", slug: "parks_and_open_spaces", color: "#059669", position: 10 },
  { name: "Education & Social Services", slug: "education_and_social_services", color: "#0891b2", position: 11 },
  { name: "Governance & Accountability", slug: "governance_and_accountability", color: "#4b5563", position: 12 },
  { name: "Disaster & Emergency", slug: "disaster_and_emergency", color: "#b91c1c", position: 13 },
  { name: "Other", slug: "other", color: "#9ca3af", position: 14 },
].freeze

CATEGORY_DEFINITIONS.each do |attrs|
  Category.find_or_create_by!(slug: attrs[:slug]) do |c|
    c.name = attrs[:name]
    c.color = attrs[:color]
    c.position = attrs[:position]
  end
end
puts "- #{Category.count} categories"

puts "Creating MCGM wards, prabhags, and boundary mapping tickets..."

# Load ward/prabhag data from JSON file
ward_data_file = File.join(Rails.root, 'db', 'ward_prabhag_data.json')
ward_data_json = JSON.parse(File.read(ward_data_file))
zones = ward_data_json['zones']

# Create admin user first (needed for ticket creation)
admin = User.find_or_create_by!(email: 'admin@mcgm.in') do |u|
  u.password = 'password123'
  u.name = 'MCGM Admin'
  u.admin = true
end

zones.each do |zone_data|
  ward_code = zone_data['ward_code']
  prabhags_count = zone_data['prabhags'].size
  puts "Creating Ward #{ward_code} with #{prabhags_count} prabhags"

  # Create ward
  ward = Ward.find_or_create_by!(ward_code: ward_code) do |w|
    w.name = zone_data['name']
    w.is_geocoded = false
  end

  # Create prabhags for this ward
  zone_data['prabhags'].each do |prabhag_data|
    prabhag_number = prabhag_data['number']
    pdf_url = prabhag_data['pdf_url']

    # Find prabhag by number only (in case it moved between wards)
    prabhag = Prabhag.find_or_initialize_by(number: prabhag_number)
    prabhag.ward_code = ward_code # Update ward assignment
    prabhag.name = "Prabhag #{prabhag_number}"
    prabhag.pdf_url = pdf_url
    prabhag.status = 'available' if prabhag.status.blank? # Only set status if not already set
    prabhag.save!
  end
end

puts "\nCreated:"
puts "- #{Ward.count} wards"
puts "- #{Prabhag.count} prabhags"
puts "- Admin user: admin@mcgm.in (password: password123)"

puts "\nData loaded from: #{ward_data_json['total_zones']} zones, #{ward_data_json['total_prabhags']} total prabhags"

puts "\nWard breakdown:"
Ward.order(:ward_code).each do |ward|
  puts "Ward #{ward.ward_code}: #{ward.prabhags.count} prabhags, #{ward.tickets.count} tickets"
end
