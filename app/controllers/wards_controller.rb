class WardsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_ward, only: [:show]

  def index
    @wards = Ward.includes(:boundaries, :prabhags).order(:ward_code)
    @total_wards = @wards.count
    @geocoded_wards = @wards.geocoded.count
    @ward_boundaries_count = @wards.joins(:boundaries).where(boundaries: { status: ['approved', 'canonical'] }).distinct.count
    @prabhag_boundaries_count = Boundary.where(boundable_type: 'Prabhag', status: ['approved', 'canonical']).count
    # Ticket system coming soon
    @total_tickets = 0
    @open_tickets = 0
    @overdue_tickets = 0

    respond_to do |format|
      format.html # renders wards/index.html.erb
      format.json # renders wards/index.json.jbuilder
    end
  end

  def show
    @prabhags = @ward.prabhags.order(:number)
    # Ticket system coming soon - use empty ActiveRecord relations
    @tickets = Ticket.none
    @open_tickets = Ticket.none
    @completed_tickets = Ticket.none

    # Get boundary data for map display using semantic finders
    @ward_boundary = @ward.approved_boundary
    # Only include prabhags with non-pending boundaries for map display
    @prabhag_boundaries = @prabhags.select { |p|
      boundary = p.approved_boundary
      boundary && boundary.status != 'pending'
    }
    # Include all prabhags for potential PNG image display (without boundaries or needing mapping)
    @all_prabhags_for_map = @prabhags
  end

  private

  def set_ward
    # Find ward by slug (using to_param method) or ward_code
    @ward = Ward.all.find { |w| w.to_param == params[:id] } || Ward.find_by!(ward_code: params[:id].upcase)
  end
end
