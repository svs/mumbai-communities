class LocationSetupController < ApplicationController
  before_action :authenticate_user!

  def show
    # Show the location setup form
  end

  def create
    address = params[:street_address]&.strip
    formatted_address = params[:formatted_address]&.strip
    latitude = params[:latitude]&.to_f
    longitude = params[:longitude]&.to_f

    if address.blank?
      flash[:alert] = "Please enter your street address"
      redirect_to setup_location_path and return
    end

    # Use coordinates if available, otherwise fall back to address matching
    if latitude && longitude && latitude != 0.0 && longitude != 0.0
      ward_code, prabhag_id = find_location_from_coordinates(latitude, longitude)
      final_address = formatted_address.present? ? formatted_address : address
    else
      ward_code, prabhag_id = find_location_from_address(address)
      final_address = address
    end

    if ward_code && prabhag_id
      current_user.set_location(final_address, ward_code, prabhag_id, latitude, longitude)
      ward_name = Ward.find_by(ward_code: ward_code)&.name
      flash[:success] = "Perfect! We found your location in Ward #{ward_code}#{ward_name ? " (#{ward_name})" : ''}. Welcome to your community!"
      redirect_to root_path
    else
      flash[:alert] = "We couldn't match your address to a specific ward and prabhag in our Mumbai database. Please try selecting a more specific address from the suggestions."
      redirect_to setup_location_path
    end
  end

  private

  def find_location_from_coordinates(latitude, longitude)
    GeocodingService.find_prabhag_from_coordinates(latitude, longitude)
  end

  def find_location_from_address(address)
    # Simplified location matching - in production you'd use proper geocoding
    # For now, let's use some basic keyword matching for demonstration

    address_lower = address.downcase

    # Sample mapping for common Mumbai areas to ward codes
    area_mappings = {
      'bandra' => ['H', 51], # Ward H, sample prabhag
      'andheri' => ['K', 72], # Ward K, sample prabhag
      'malad' => ['P', 101],  # Sample mapping
      'borivali' => ['R', 120], # Sample mapping
      'colaba' => ['A', 225],   # Sample mapping
      'churchgate' => ['B', 223], # Sample mapping
      'mumbai central' => ['C', 220], # Sample mapping
      'dadar' => ['F', 172],    # Sample mapping
      'mahim' => ['G', 182],    # Sample mapping
    }

    area_mappings.each do |area, (ward_code, prabhag_number)|
      if address_lower.include?(area)
        # Find the actual prabhag by number and ward
        prabhag = Prabhag.find_by(number: prabhag_number, ward_code: ward_code)
        return [ward_code, prabhag&.id] if prabhag
      end
    end

    # If no match found, return nil
    [nil, nil]
  end
end