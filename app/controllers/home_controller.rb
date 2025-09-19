class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  def index
    # If user is logged in and has a location, redirect to their prabhag page
    if user_signed_in? && current_user.has_location?
      ward = Ward.find_by(ward_code: current_user.ward_code)
      prabhag = Prabhag.find(current_user.prabhag_id)
      redirect_to ward_prabhag_path(ward, prabhag) and return
    end
    # Statistics for dashboard
    @total_wards = Ward.count
    @active_communities = Ward.includes(:boundaries, :prabhags).select(&:fully_boundary_mapped?).count
    @total_issues_resolved = 0 # Ticket system coming soon
    @events_this_month = 0 # Placeholder - implement when events system exists
    @total_citizens = User.count

    # Recent activity feed - tickets coming soon
    @recent_tickets = []

    # Ward data for map and community preview
    @wards_by_activity = {
      active: [],
      growing: [],
      inactive: []
    }

    # Feature wards for display - temporarily without ticket joins
    @featured_wards = Ward.includes(:boundaries).limit(6)

    # User's current assignments if logged in
    if user_signed_in?
      @user_assignments = current_user.current_assignments if current_user.respond_to?(:current_assignments)
      # User tickets coming soon
    end
  end
end
