module Wards
  class FacilitiesController < ApplicationController
    skip_before_action :authenticate_user!
    before_action :set_ward

    def index
      @facilities = @ward.facilities.order(:facility_type, :name)

      respond_to do |format|
        format.html
        format.json
      end
    end

    def scorecard
      @comparison = FacilityComparisonService.compare(ward_code: @ward.ward_code)
      @type_counts = @ward.facilities.group(:facility_type, :source).count
    end

    private

    def set_ward
      @ward = Ward.all.find { |w| w.to_param == params[:ward_id] } || Ward.find_by!(ward_code: params[:ward_id].upcase)
    end
  end
end
