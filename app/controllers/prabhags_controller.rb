class PrabhagsController < ApplicationController
  include ActionView::Helpers::DateHelper

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
    # Get related ward if available
    if @ward.blank? && @prabhag.ward_code.present?
      @ward = Ward.find_by(ward_code: @prabhag.ward_code)
    end

    # For approved prabhags, load community data
    if @prabhag.status == 'approved'
      load_community_data
    end

    respond_to do |format|
      format.html
      format.json # Uses show.json.jbuilder template
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

    # Load existing boundary for verification if it exists
    @existing_boundary = @prabhag.boundaries.best.first
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
      # Handle nested route: /wards/:ward_id/prabhags/:id
      slug_name = params[:ward_id].gsub('-', ' ').titleize
      ward = Ward.find_by(name: slug_name) || Ward.find_by!(ward_code: params[:ward_id].upcase)
      @prabhag = ward.prabhags.find(params[:id])
      @ward = ward
    else
      # Handle direct route: /prabhags/:id (find handles both number and id)
      @prabhag = Prabhag.find(params[:id])
    end
  end

  def load_community_data
    # Load tickets (issues) for this prabhag
    @recent_tickets = @prabhag.tickets.includes(:created_by, :assigned_to)
                                    .order(created_at: :desc)
                                    .limit(10)

    # Get community statistics
    @community_stats = {
      active_issues: @prabhag.tickets.where(status: ['open', 'assigned', 'in_progress']).count,
      active_neighbors: User.joins("JOIN tickets ON users.id = tickets.created_by_id")
                           .where("tickets.prabhag_number = ? AND tickets.ward_code = ?", @prabhag.number, @prabhag.ward_code)
                           .distinct.count,
      resolution_rate: calculate_resolution_rate,
      new_members_this_week: User.joins("JOIN tickets ON users.id = tickets.created_by_id")
                                .where("tickets.prabhag_number = ? AND tickets.ward_code = ? AND tickets.created_at > ?",
                                       @prabhag.number, @prabhag.ward_code, 1.week.ago)
                                .distinct.count
    }

    # Events will be loaded when Event model is implemented
    # For now, @upcoming_events remains nil for graceful degradation
    @upcoming_events = nil

    # Recent activity feed
    @recent_activity = []

    # Add recent tickets to activity feed
    @prabhag.tickets.includes(:created_by).order(created_at: :desc).limit(5).each do |ticket|
      @recent_activity << {
        type: 'issue',
        icon: '<i class="fas fa-exclamation-triangle"></i>',
        text: "New issue: #{ticket.title}",
        time: time_ago_in_words(ticket.created_at) + ' ago',
        created_at: ticket.created_at
      }
    end

    # Sort activity by actual timestamp (most recent first)
    @recent_activity.sort_by! { |activity| activity[:created_at] }.reverse!
  end

  def calculate_resolution_rate
    total_tickets = @prabhag.tickets.count
    return 0 if total_tickets == 0

    completed_tickets = @prabhag.tickets.completed.count
    ((completed_tickets.to_f / total_tickets) * 100).round
  end

  def prabhag_json_data
    data = {
      id: @prabhag.id,
      number: @prabhag.number,
      ward_code: @prabhag.ward_code,
      status: @prabhag.status,
      pdf_url: @prabhag.pdf_url
    }

    if @ward
      data[:ward] = {
        name: @ward.name,
        population_estimate: @ward.population_estimate
      }
    end

    if @prabhag.status == 'approved'
      data[:community] = {
        stats: @community_stats,
        recent_tickets: @recent_tickets.map do |ticket|
          {
            id: ticket.id,
            title: ticket.title,
            description: ticket.description,
            status: ticket.status,
            created_at: ticket.created_at,
            created_by: ticket.created_by.name || ticket.created_by.email.split('@').first
          }
        end,
        recent_activity: @recent_activity
      }
    end

    data
  end
end
