# We don't clear existing data - we update it to preserve relationships

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
