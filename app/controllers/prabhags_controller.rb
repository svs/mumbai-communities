class PrabhagsController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_prabhag, only: [ :show, :assign, :trace, :submit ]

  def index
    @wards = Prabhag.distinct.pluck(:ward_code).compact.sort

    # Filter by ward if ward_id parameter is provided
    if params[:ward_id].present?
      @prabhags = Prabhag.for_ward(params[:ward_id])
      @ward_name = params[:ward_id]
    else
      @prabhags = Prabhag.all
    end

    @available_prabhags = @prabhags.available.order(:ward_code, :number)
    @total_prabhags = @prabhags.count
    @completed_prabhags = @prabhags.approved.count
    @assigned_prabhags = @prabhags.where(status: [ "assigned", "submitted" ]).count
  end

  def show
    # No need for separate ward object
  end

  def assign
    if @prabhag.can_be_assigned_to?(current_user)
      @prabhag.assign_to!(current_user)
      redirect_to trace_prabhag_path(@prabhag), notice: "Prabhag assigned to you! Start tracing the boundary."
    else
      redirect_to @prabhag, alert: "This prabhag is not available for assignment."
    end
  end

  def trace
    redirect_to @prabhag, alert: "Access denied." unless @prabhag.assigned_to == current_user
  end

  def submit
    if @prabhag.assigned_to == current_user
      boundary_data = params[:boundary_geojson]
      if boundary_data.present?
        @prabhag.submit_boundary!(boundary_data)
        redirect_to @prabhag, notice: "Boundary submitted for review!"
      else
        redirect_to trace_prabhag_path(@prabhag), alert: "Please trace the boundary before submitting."
      end
    else
      redirect_to @prabhag, alert: "Access denied."
    end
  end

  private

  def set_prabhag
    @prabhag = Prabhag.find(params[:id])
  end
end
