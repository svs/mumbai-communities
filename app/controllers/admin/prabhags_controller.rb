class Admin::PrabhagsController < Admin::BaseController
  before_action :set_prabhag, only: [:show, :boundary_review]

  def index
    @submitted_prabhags = Prabhag.submitted.includes(:assigned_to)
    @approved_prabhags = Prabhag.approved.includes(:assigned_to)
    @rejected_prabhags = Prabhag.rejected.includes(:assigned_to)
    
    @total_submitted = @submitted_prabhags.count
    @total_approved = @approved_prabhags.count
    @total_rejected = @rejected_prabhags.count
  end

  def show
    # Get the boundary data from the most recent pending boundary or the best available boundary
    @pending_boundary = @prabhag.boundaries.where(status: 'pending').order(:created_at).last
    @current_boundary = @pending_boundary || @prabhag.boundary

    if @current_boundary&.geojson&.present?
      begin
        @geojson_data = JSON.parse(@current_boundary.geojson)
      rescue JSON::ParserError
        # Handle malformed JSON gracefully
        @geojson_data = nil
      end
    end
  end

  def boundary_review
    # Get boundaries for review (pending user submissions)
    @boundaries_for_review = @prabhag.boundaries.for_admin_review.includes(:submitted_by, :edited_by)

    respond_to do |format|
      format.html # renders boundary_review.html.erb
      format.json # renders boundary_review.json.jbuilder
    end
  end

  private

  def set_prabhag
    @prabhag = Prabhag.find(params[:id])
  end

end
