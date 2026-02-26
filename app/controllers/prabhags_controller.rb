class PrabhagsController < ApplicationController
  include ActionView::Helpers::DateHelper

  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_prabhag, only: [ :show, :assign, :trace, :submit ]

  def index
    @wards = Prabhag.distinct.pluck(:ward_code).compact.sort

    # Filter by ward if ward_id parameter is provided
    if params[:ward_id].present?
      slug_name = params[:ward_id].gsub('-', ' ').titleize
      @ward = Ward.find_by(name: slug_name) || Ward.find_by!(ward_code: params[:ward_id].upcase)
      @prabhags = Prabhag.for_ward(@ward.ward_code)
      @ward_name = @ward.name
    else
      @prabhags = Prabhag.all
    end

    @all_prabhags = @prabhags.includes(:assigned_to, :boundaries).order(:number)
    @available_prabhags = @prabhags.available.order(:ward_code, :number)
    @total_prabhags = @prabhags.count
    @completed_prabhags = @prabhags.approved.count
    @assigned_prabhags = @prabhags.where(status: [ "assigned", "submitted" ]).count
  end

  def show
    if @ward.blank? && @prabhag.ward_code.present?
      @ward = Ward.find_by(ward_code: @prabhag.ward_code)
    end

    @boundary = @prabhag.boundary
    @stage = @prabhag.lifecycle_stage

    # Load POIs for mapped prabhags (approved boundary + live OSM query)
    if @boundary&.geojson.present? && @boundary.status != 'pending'
      @pois = Rails.cache.fetch("prabhag/#{@prabhag.id}/pois/v1", expires_in: 24.hours) do
        @prabhag.pois rescue []
      end
      @poi_groups = @pois.group_by { |poi| poi[:type] }
    else
      @pois = []
      @poi_groups = {}
    end

    # Fallback: stored facilities filtered to within prabhag boundary
    if @poi_groups.empty? && @ward && @boundary&.geojson.present?
      @prabhag_facilities = Rails.cache.fetch("prabhag/#{@prabhag.id}/facilities/v1", expires_in: 24.hours) do
        @ward.facilities.where.not(latitude: nil, longitude: nil)
             .select { |f| @boundary.contains_point?(f.latitude, f.longitude) }
      end
      @ward_facility_counts = @prabhag_facilities.group_by(&:facility_type).transform_values(&:count)
    elsif @poi_groups.empty? && @ward
      @prabhag_facilities = []
      @ward_facility_counts = @ward.facilities.group(:facility_type).count
    else
      @prabhag_facilities = []
      @ward_facility_counts = {}
    end

    respond_to do |format|
      format.html
      format.json
    end
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

    # Load existing boundary to help with tracing if one exists
    @existing_boundary = @prabhag.boundaries.best
  end

  def submit
    if @prabhag.assigned_to == current_user
      boundary_data = params[:boundary_geojson]
      if boundary_data.present?
        @prabhag.submit_boundary!(boundary_data, submitted_by: current_user)
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
    if params[:ward_id].present?
      slug_name = params[:ward_id].gsub('-', ' ').titleize
      ward = Ward.find_by(name: slug_name) || Ward.find_by!(ward_code: params[:ward_id].upcase)
      @prabhag = ward.prabhags.find_by(number: params[:id]) || ward.prabhags.find(params[:id])
      @ward = ward
    else
      @prabhag = Prabhag.find(params[:id])
    end
  end
end
