class LocationSetupController < ApplicationController
  before_action :authenticate_user!

  def show
    # Show the location setup form
  end

  def create
    latitude = params[:latitude]&.to_f
    longitude = params[:longitude]&.to_f
    address = params[:formatted_address] || params[:street_address]

    ward_code, prabhag_id = GeocodingService.find_prabhag_from_coordinates(latitude, longitude)

    if ward_code && prabhag_id
      current_user.set_location(address, ward_code, prabhag_id, latitude, longitude)
      redirect_to root_path
    else
      redirect_to setup_location_path
    end
  end

end