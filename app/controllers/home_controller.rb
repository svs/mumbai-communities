class HomeController < ApplicationController
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
    @total_issues_resolved = Ticket.where(status: ['approved', 'closed']).count
    @events_this_month = 0 # Placeholder - implement when events system exists
    @total_citizens = User.count

    # Recent activity feed
    @recent_tickets = Ticket.includes(:ward)
                           .where('created_at > ?', 1.week.ago)
                           .order(created_at: :desc)
                           .limit(5)

    # Ward data for map and community preview
    all_wards = Ward.includes(:boundaries, :tickets)
    @wards_by_activity = {
      active: [],
      growing: [],
      inactive: []
    }

    # We'll categorize in the view using helpers

    # Feature wards for display
    @featured_wards = Ward.includes(:boundaries, :tickets)
                         .joins(:tickets)
                         .group('wards.id')
                         .order('COUNT(tickets.id) DESC')
                         .limit(6)

    # User's current assignments if logged in
    if user_signed_in?
      @user_assignments = current_user.current_assignments if current_user.respond_to?(:current_assignments)
      @user_tickets = current_user.active_tickets if current_user.respond_to?(:active_tickets)
    end
  end
end
