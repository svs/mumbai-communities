class WardsController < ApplicationController
  before_action :set_ward, only: [:show]

  def index
    @wards = Ward.includes(:boundaries, :prabhags).order(:ward_code)
    @total_wards = @wards.count
    @geocoded_wards = @wards.geocoded.count
    @ward_boundaries_count = @wards.joins(:boundaries).where(boundaries: { status: ['approved', 'canonical'] }).distinct.count
    @prabhag_boundaries_count = Boundary.where(boundable_type: 'Prabhag', status: ['approved', 'canonical']).count
    @total_tickets = Ticket.count
    @open_tickets = Ticket.open.count
    @overdue_tickets = Ticket.overdue.count

    respond_to do |format|
      format.html # renders wards/index.html.erb
      format.json # renders wards/index.json.jbuilder
    end
  end

  def show
    @prabhags = @ward.prabhags.order(:number)
    @tickets = @ward.tickets.includes(:assigned_to).order(:status, :priority, :due_date)
    @open_tickets = @tickets.where(status: ['open', 'assigned', 'in_progress'])
    @completed_tickets = @tickets.completed

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
    # Find ward by name slug or ward_code
    slug_name = params[:id].gsub('-', ' ').titleize
    @ward = Ward.find_by(name: slug_name) || Ward.find_by!(ward_code: params[:id].upcase)
  end
end
