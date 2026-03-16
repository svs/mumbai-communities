namespace :governance do
  desc "Import ward governance data from parsed JSON"
  task import: :environment do
    json_path = ENV.fetch("GOVERNANCE_JSON", Rails.root.join("db/data/parsed_ward_officers.json"))
    unless File.exist?(json_path)
      puts "ERROR: #{json_path} not found. Run the parser first."
      exit 1
    end

    data = JSON.parse(File.read(json_path))

    # Map ward codes from email list format to our ward_code format
    WARD_CODE_MAP = {
      "A" => "A", "B" => "B", "C" => "C", "D" => "D", "E" => "E",
      "F_South" => "F SOUTH", "F_North" => "F NORTH",
      "G_South" => "G SOUTH", "G_North" => "G NORTH",
      "H_East" => "H EAST", "H_West" => "H WEST",
      "K_East" => "K EAST", "K_West" => "K WEST",
      "L" => "L", "M_East" => "M EAST", "M_West" => "M WEST",
      "N" => "N", "P_South" => "P SOUTH", "P_North" => "P NORTH",
      "R_South" => "R SOUTH", "R_North" => "R/North", "R_Central" => "R/Central",
      "S" => "S", "T" => "T"
    }.freeze

    DESIGNATION_LEVELS = {
      "Assistant Commissioner" => "senior",
      "Executive Engineer" => "senior",
      "Medical Officer" => "senior",
      "Medical Officer Health" => "senior",
      "Medical Offier of Health" => "senior",
      "Assessment Assessor and collector" => "senior",
      "Assistant Assessor and Collector" => "senior",
      "Asstt. Assessor & Collector" => "senior",
      "Administrative Officer" => "senior",
      "Colony Officer" => "senior",
      "Sr. Inspector" => "senior",
      "Pest Control Officer" => "senior",
      "Complaint Officer" => "senior",
      "Assistant Engineer" => "mid",
      "Assistant Engineer-I" => "mid",
      "Assistant Engineer-II" => "mid",
      "Road Engineer" => "mid",
      "Horticultural Assistant" => "mid",
      "Asst. Supdt. of Garden" => "mid",
      "Assistant Law Officer- City Civil Court" => "mid",
      "Assistant Security Officer" => "mid",
      "Sub Engineer" => "junior",
      "Junior Engineer" => "junior",
      "Junior Tree Officer" => "junior",
      "Head Clerk" => "junior"
    }.freeze

    # Create or find BMC as top-level organisation
    bmc = Organisation.find_or_create_by!(name: "BMC", org_type: "municipal_corporation") do |org|
      org.website = "https://www.mcgm.gov.in"
      org.jurisdiction = "Greater Mumbai"
    end
    puts "Organisation: #{bmc.name} (id: #{bmc.id})"

    total_positions = 0
    total_departments = 0
    wards_processed = 0

    data["wards"].each do |parsed_code, ward_data|
      ward_code = WARD_CODE_MAP[parsed_code]
      unless ward_code
        puts "  SKIP: No mapping for ward code '#{parsed_code}'"
        next
      end

      ward = Ward.find_by(ward_code: ward_code)
      unless ward
        # Try alternate formats
        ward = Ward.find_by(ward_code: parsed_code)
      end
      unless ward
        puts "  SKIP: Ward '#{ward_code}' not found in database"
        next
      end

      # Create ward organisation linked to the Ward model
      ward_org = Organisation.find_or_create_by!(
        organisable: ward,
        org_type: "ward"
      ) do |org|
        org.name = "Ward #{ward.ward_code}"
        org.parent = bmc
      end

      ward_data["sections"].each do |section_name, officers|
        dept = Department.find_or_create_by!(
          organisation: ward_org,
          name: section_name
        )
        total_departments += 1

        officers.each do |officer|
          level = DESIGNATION_LEVELS[officer["designation"]] || "other"

          Position.find_or_create_by!(
            department: dept,
            designation: officer["designation"],
            email: officer["email"]
          ) do |pos|
            pos.level = level
          end
          total_positions += 1
        end
      end

      wards_processed += 1
      puts "  Ward #{ward.ward_code}: #{ward_data['sections'].keys.count} departments, #{ward_data['sections'].values.flatten.count} positions"
    end

    puts "\nDone!"
    puts "  Wards processed: #{wards_processed}"
    puts "  Departments created: #{total_departments}"
    puts "  Positions created: #{total_positions}"
  end

  desc "Import 2026 BMC election results (corporators per prabhag)"
  task import_corporators: :environment do
    json_path = Rails.root.join("tmp/bmc_data/bmc_election_results_2026.json")
    unless File.exist?(json_path)
      puts "ERROR: #{json_path} not found."
      exit 1
    end

    results = JSON.parse(File.read(json_path))

    bmc = Organisation.find_or_create_by!(name: "BMC", org_type: "municipal_corporation") do |org|
      org.website = "https://www.mcgm.gov.in"
      org.jurisdiction = "Greater Mumbai"
    end

    imported = 0
    skipped = 0

    results.each do |result|
      ward_number = result["ward"]
      prabhag = Prabhag.find_by(number: ward_number)

      unless prabhag
        puts "  SKIP: Prabhag #{ward_number} not found"
        skipped += 1
        next
      end

      # Find or create the ward-level organisation (parent for this prabhag)
      ward = prabhag.ward
      ward_org = Organisation.find_by(organisable: ward, org_type: "ward") if ward

      # Create prabhag organisation
      prabhag_org = Organisation.find_or_create_by!(
        organisable: prabhag,
        org_type: "prabhag"
      ) do |org|
        org.name = "Prabhag #{prabhag.number}"
        org.parent = ward_org || bmc
      end

      # Create "Elected Representatives" department
      dept = Department.find_or_create_by!(
        organisation: prabhag_org,
        name: "Elected Representatives"
      )

      # Create corporator position
      Position.find_or_create_by!(
        department: dept,
        designation: "Corporator",
        person_name: result["winner"]
      ) do |pos|
        pos.elected = true
        pos.political_party = result["party"]
        pos.level = "senior"
      end

      imported += 1
      puts "  Prabhag #{ward_number}: #{result['winner']} (#{result['party']})"
    end

    puts "\nDone! Imported: #{imported}, Skipped: #{skipped}"
  end

  desc "Clear all governance data"
  task clear: :environment do
    Position.delete_all
    Department.delete_all
    Organisation.delete_all
    puts "Cleared all governance data."
  end
end
