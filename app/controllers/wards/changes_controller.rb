module Wards
  class ChangesController < ApplicationController
    skip_before_action :authenticate_user!
    before_action :set_ward

    def index
      @recent_facilities = @ward.facilities
        .where("last_seen_at > ? OR created_at > ?", 7.days.ago, 7.days.ago)
        .order(created_at: :desc)
        .limit(50)

      @snapshots = @ward.ward_data_snapshots.latest.limit(20)
    end

    private

    def set_ward
      @ward = Ward.all.find { |w| w.to_param == params[:ward_id] } || Ward.find_by!(ward_code: params[:ward_id].upcase)
    end
  end
end
