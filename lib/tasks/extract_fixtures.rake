namespace :db do
  desc "Extract development database data to test fixtures"
  task extract_fixtures: :environment do
    models_to_extract = [
      { model: Ward, filename: 'wards.yml' },
      { model: Prabhag, filename: 'prabhags.yml' },
      { model: Boundary, filename: 'boundaries.yml' },
      { model: User, filename: 'users.yml' }
      # Skip Ticket for now to avoid foreign key issues
    ]

    puts "Extracting fixtures from development database..."

    models_to_extract.each do |config|
      model_class = config[:model]
      filename = config[:filename]

      puts "Processing #{model_class.name}..."

      # Get all records
      records = model_class.all

      if records.empty?
        puts "  No #{model_class.name} records found, skipping..."
        next
      end

      # Build YAML structure
      fixture_data = {}

      records.each_with_index do |record, index|
        # Create a fixture name
        fixture_name = generate_fixture_name(record, index)

        # Extract attributes
        attributes = record.attributes.except('created_at', 'updated_at')

        # Handle special cases for different models
        attributes = process_model_attributes(model_class, attributes, record)

        fixture_data[fixture_name] = attributes
      end

      # Write to fixture file
      fixture_path = Rails.root.join('test', 'fixtures', filename)
      File.write(fixture_path, fixture_data.to_yaml)

      puts "  ✓ Created #{filename} with #{records.count} records"
    end

    puts "\nFixture extraction complete!"
    puts "Run: rails test to use the new fixtures"
  end

  private

  def generate_fixture_name(record, index)
    # Try to use meaningful names based on the model
    case record.class.name
    when 'Ward'
      "ward_#{record.ward_code}"
    when 'Prabhag'
      "prabhag_#{record.ward_code}_#{record.number}"
    when 'Boundary'
      "boundary_#{record.boundable_type&.downcase}_#{record.boundable_id}_#{index + 1}"
    when 'User'
      email_prefix = record.email&.split('@')&.first&.gsub(/[^a-z0-9]/i, '_') || "user"
      "#{email_prefix}_#{record.id}"
    when 'Ticket'
      title_slug = record.title&.parameterize&.underscore&.first(20) || "ticket"
      "#{title_slug}_#{record.id}"
    else
      "#{record.class.name.downcase}_#{index + 1}"
    end
  end

  def process_model_attributes(model_class, attributes, record)
    case model_class.name
    when 'Boundary'
      # Handle GeoJSON serialization for boundaries
      if record.geojson.present?
        # Keep geojson as-is since it's already serialized
        attributes['geojson'] = record.geojson
      end

    when 'User'
      # Mask sensitive data but keep them functional
      attributes['encrypted_password'] = '$2a$12$' + 'a' * 57 # Dummy bcrypt hash
      attributes['email'] = attributes['email']&.gsub(/@.*/, '@example.com')
      # Remove sensitive timestamps that might cause issues
      attributes.delete('remember_created_at')
      attributes.delete('reset_password_sent_at')
      attributes.delete('confirmed_at')

    when 'Prabhag'
      # Prabhag uses ward_code, not ward_id
      # Clean up any null assigned_to_id to avoid foreign key issues
      if attributes['assigned_to_id'].nil?
        attributes.delete('assigned_to_id')
      end

    when 'Ticket'
      # Clean up foreign key references for tickets
      if attributes['ward_id'].nil?
        attributes.delete('ward_id')
      end
      if attributes['assigned_to_id'].nil?
        attributes.delete('assigned_to_id')
      end
    end

    # Remove nil values and problematic timestamp fields
    attributes.delete('remember_created_at') if attributes['remember_created_at'].nil?
    attributes.compact
  end
end