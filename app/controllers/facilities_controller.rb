class FacilitiesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :show ]

  def show
    @facility = Facility.find(params[:id])
    @ward = @facility.ward
    @prabhag = Prabhag.find_by(number: @facility.prabhag_number, ward_code: @facility.ward_code)
  end
end
