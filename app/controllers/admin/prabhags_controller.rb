class Admin::PrabhagsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  before_action :set_prabhag, only: [:show, :approve, :reject]

  def index
    @submitted_prabhags = Prabhag.submitted.includes(:assigned_to)
    @approved_prabhags = Prabhag.approved.includes(:assigned_to)
    @rejected_prabhags = Prabhag.rejected.includes(:assigned_to)
    
    @total_submitted = @submitted_prabhags.count
    @total_approved = @approved_prabhags.count
    @total_rejected = @rejected_prabhags.count
  end

  def show
    @geojson_data = JSON.parse(@prabhag.boundary_geojson) if @prabhag.boundary_geojson.present?
  end

  def approve
    @prabhag.approve!
    redirect_to admin_prabhag_path(@prabhag), notice: 'Prabhag boundary approved successfully!'
  end

  def reject
    @prabhag.reject!
    redirect_to admin_prabhag_path(@prabhag), notice: 'Prabhag boundary rejected. It has been made available for reassignment.'
  end

  private

  def set_prabhag
    @prabhag = Prabhag.find(params[:id])
  end

  def ensure_admin!
    redirect_to root_path, alert: 'Access denied. Admin privileges required.' unless current_user&.admin?
  end
end
