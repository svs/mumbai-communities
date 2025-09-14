namespace :wards do
  desc "Populate short_name field for all wards using WardCodeMapper"
  task populate_short_names: :environment do
    puts "🏢 Populating short_name field for all wards..."

    updated_count = 0
    skipped_count = 0

    Ward.find_each do |ward|
      begin
        # Use WardCodeMapper to get the short format (KML format)
        short_name = WardCodeMapper.to_kml_format(ward.ward_code)

        # If no mapping found, use the ward_code as-is
        short_name ||= ward.ward_code

        if ward.short_name != short_name
          ward.update!(short_name: short_name)
          puts "✅ Updated Ward #{ward.ward_code}: '#{ward.name}' -> short_name: '#{short_name}'"
          updated_count += 1
        else
          puts "⏭️  Ward #{ward.ward_code} already has correct short_name: '#{short_name}'"
          skipped_count += 1
        end

      rescue => e
        puts "❌ Error updating Ward #{ward.ward_code}: #{e.message}"
      end
    end

    puts "\n📊 Ward Short Name Population Summary:"
    puts "   Updated: #{updated_count}"
    puts "   Skipped: #{skipped_count}"
    puts "   Total processed: #{updated_count + skipped_count}"

    # Show some examples
    puts "\n📝 Sample short names:"
    Ward.limit(10).each do |ward|
      puts "   #{ward.ward_code} (#{ward.name}) -> #{ward.short_name}"
    end
  end
end