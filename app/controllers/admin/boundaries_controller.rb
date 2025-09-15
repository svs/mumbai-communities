class Admin::BoundariesController < Admin::BaseController
  before_action :set_boundary, only: [:show, :edit, :update, :destroy, :approve, :reject]

  def index
    @boundaries = Boundary.includes(:boundable, :submitted_by, :approved_by)
                          .order(:created_at => :desc)
                          .page(params[:page])

    # Filter by status if provided
    @boundaries = @boundaries.where(status: params[:status]) if params[:status].present?

    # Filter by boundable type if provided
    @boundaries = @boundaries.where(boundable_type: params[:type]) if params[:type].present?
  end

  def show
    @geojson_data = JSON.parse(@boundary.geojson) if @boundary.geojson.present?

    respond_to do |format|
      format.html
      format.json # renders show.json.jbuilder
    end
  end

  def edit
    # @boundary is already set by before_action :set_boundary
  end

  def update
    if BoundaryUpdateService.update_with_admin_tracking(@boundary, boundary_params, current_user)
      redirect_to_appropriate_path('Boundary updated successfully.')
    else
      render :edit
    end
  end

  def destroy
    @boundary.destroy
    redirect_to admin_boundaries_path, notice: 'Boundary deleted successfully.'
  end

  def approve
    @boundary.approve!(current_user)
    handle_prabhag_status_update if @boundary.prabhag?
    notice_message = @boundary.prabhag? ? 'Prabhag boundary approved successfully!' : 'Boundary approved successfully!'
    redirect_to_appropriate_path(notice_message)
  rescue StandardError => e
    handle_approval_error(e, 'approve')
  end

  def reject
    rejection_reason = params[:rejection_reason] || 'Rejected by admin'
    @boundary.reject!(current_user, rejection_reason)
    handle_prabhag_rejection if @boundary.prabhag?
    notice_message = @boundary.prabhag? ? 'Prabhag boundary rejected. It has been made available for reassignment.' : 'Boundary rejected.'
    redirect_to_appropriate_path(notice_message)
  rescue StandardError => e
    handle_approval_error(e, 'reject')
  end

  private

  def set_boundary
    @boundary = Boundary.find(params[:id])
  end

  def boundary_params
    params.require(:boundary).permit(:geojson, :status, :rejection_reason, :year, :metadata)
  end



  def redirect_to_appropriate_path(notice_message)
    if @boundary.prabhag?
      redirect_to admin_prabhag_path(@boundary.boundable), notice: notice_message
    else
      redirect_to admin_boundaries_path, notice: notice_message
    end
  end

  def handle_prabhag_status_update
    PrabhagStatusService.update_after_boundary_approval(@boundary.boundable)
  end

  def handle_prabhag_rejection
    PrabhagStatusService.update_after_boundary_rejection(@boundary.boundable)
  end

  def handle_approval_error(error, action)
    alert_message = "Cannot #{action}: #{error.message}"
    if @boundary.prabhag?
      redirect_to admin_prabhag_path(@boundary.boundable), alert: alert_message
    else
      redirect_to admin_boundaries_path, alert: alert_message
    end
  end
end