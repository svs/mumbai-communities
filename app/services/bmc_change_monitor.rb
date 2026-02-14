class BmcChangeMonitor
  OUTPUT_PATH = Rails.root.join("tmp", "bmc_changes.txt")

  class << self
    def run
      changes = []

      # Check portal page changes
      changes.concat(detect_snapshot_changes)

      # Check facility changes (new/removed ArcGIS facilities)
      changes.concat(detect_facility_changes)

      write_report(changes)
      changes
    end

    private

    def detect_snapshot_changes
      changes = []

      Ward.pluck(:ward_code).each do |ward_code|
        WardDataSnapshot::DATA_TYPES.each do |data_type|
          snapshots = WardDataSnapshot
            .for_ward(ward_code)
            .of_type(data_type)
            .latest
            .limit(2)
            .to_a

          next if snapshots.empty?

          current = snapshots.first
          previous = snapshots.second

          if previous.nil?
            changes << {
              type: :new,
              category: :snapshot,
              ward_code: ward_code,
              data_type: data_type,
              url: current.source_url,
              hash: current.content_hash,
              timestamp: current.created_at
            }
          elsif current.content_hash != previous.content_hash
            changes << {
              type: :changed,
              category: :snapshot,
              ward_code: ward_code,
              data_type: data_type,
              url: current.source_url,
              previous_hash: previous.content_hash,
              new_hash: current.content_hash,
              timestamp: current.created_at
            }
          end
        end
      end

      changes
    end

    def detect_facility_changes
      changes = []
      cutoff = 24.hours.ago

      # New facilities (created in last 24 hours)
      Facility.from_bmc.where("created_at > ?", cutoff).find_each do |facility|
        changes << {
          type: :new,
          category: :facility,
          ward_code: facility.ward_code,
          name: facility.name,
          facility_type: facility.facility_type,
          latitude: facility.latitude,
          longitude: facility.longitude,
          timestamp: facility.created_at
        }
      end

      # Stale facilities (not seen in 7 days, previously seen)
      Facility.from_bmc
        .where("last_seen_at < ?", 7.days.ago)
        .where.not(last_seen_at: nil)
        .find_each do |facility|
        changes << {
          type: :removed,
          category: :facility,
          ward_code: facility.ward_code,
          name: facility.name,
          facility_type: facility.facility_type,
          last_seen: facility.last_seen_at,
          timestamp: Time.current
        }
      end

      changes
    end

    def write_report(changes)
      FileUtils.mkdir_p(File.dirname(OUTPUT_PATH))

      File.open(OUTPUT_PATH, "w") do |f|
        f.puts "=== BMC Change Report — #{Time.current.strftime('%Y-%m-%d %H:%M')} ==="
        f.puts

        if changes.empty?
          f.puts "No changes detected."
          return
        end

        changes.group_by { |c| c[:type] }.each do |type, group|
          group.each do |change|
            label = type.to_s.upcase
            case change[:category]
            when :snapshot
              f.puts "[#{label}] Ward #{change[:ward_code]} — #{change[:data_type].titleize} Page"
              f.puts "  URL: #{change[:url]}"
              if change[:previous_hash]
                f.puts "  Previous hash: #{change[:previous_hash][0..11]}"
                f.puts "  New hash: #{change[:new_hash][0..11]}"
              else
                f.puts "  Hash: #{change[:hash][0..11]}"
              end
              f.puts "  At: #{change[:timestamp]}"
            when :facility
              f.puts "[#{label}] Ward #{change[:ward_code]} — ArcGIS #{change[:facility_type].titleize}"
              f.puts "  Name: \"#{change[:name]}\""
              if change[:latitude]
                f.puts "  Location: #{change[:latitude]}, #{change[:longitude]}"
              end
              if change[:last_seen]
                f.puts "  Last seen: #{change[:last_seen]}"
              end
            end
            f.puts
          end
        end
      end

      Rails.logger.info "BmcChangeMonitor: Report written to #{OUTPUT_PATH} (#{changes.size} changes)"
    end
  end
end
