class WardsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show, :info, :news, :locate, :officials, :facilities_tab, :issues_tab]
  before_action :set_ward, only: [:show, :info, :news, :officials, :facilities_tab, :issues_tab]
  before_action :set_variant, only: [:show, :info, :news, :officials, :facilities_tab, :issues_tab]

  def index
    @wards = Ward.includes(:boundaries, :prabhags).order(:ward_code)
    @tweets = Tweet.includes(:ward).original.recent
    @tweets = @tweets.where(category: params[:category]) if params[:category].present?
    @tweets = @tweets.page(params[:page]).per(10)
    @ward_tweet_counts = Tweet.original.group(:ward_id).count
    @total_tweet_count = Tweet.original.count
    @category_counts = Tweet.original.where.not(category: nil).group(:category).count

    respond_to do |format|
      format.html
      format.json
    end
  end

  def show
    @prabhags = @ward.prabhags.order(:number)
    # Ticket system coming soon - use empty ActiveRecord relations
    @tickets = Ticket.none
    @open_tickets = Ticket.none
    @completed_tickets = Ticket.none

    @tweets = @ward.tweets.original.recent.limit(20)
    @category_counts = @ward.tweets.original.where.not(category: nil).group(:category).count
    @facility_type_counts = @ward.facilities.group(:facility_type).count

    # Get boundary data for map display using semantic finders
    @ward_boundary = @ward.approved_boundary
    # Only include prabhags with non-pending boundaries for map display
    @prabhag_boundaries = @prabhags.select { |p|
      boundary = p.approved_boundary
      boundary && boundary.status != 'pending'
    }
    # Include all prabhags for potential PNG image display (without boundaries or needing mapping)
    @all_prabhags_for_map = @prabhags

    # Governance structure
    @organisation = @ward.organisation
    if @organisation
      @departments = @organisation.departments.includes(:positions).ordered
    end
  end

  def info
    redirect_to officials_ward_path(@ward), status: :moved_permanently
  end

  def officials
    @organisation = @ward.organisation
    @positions = if @organisation
      @organisation.positions.active.ordered.includes(:person)
    else
      Position.none
    end
  end

  def facilities_tab
    @prabhags = @ward.prabhags.order(:number)
    @facility_type_counts = @ward.facilities.group(:facility_type).count

    @ward_boundary = @ward.approved_boundary
    @prabhag_boundaries = @prabhags.select { |p|
      boundary = p.approved_boundary
      boundary && boundary.status != 'pending'
    }
    @all_prabhags_for_map = @prabhags
  end

  def issues_tab
    @issues = @ward.issues.order(created_at: :desc).limit(20)
    @discussions = @ward.discussions.order(created_at: :desc).limit(20)
  end

  def locate
    if params[:lat].blank? || params[:lng].blank?
      redirect_to wards_path and return
    end

    boundary = Boundary.active.for_type('Ward').find_each do |b|
      break b if b.contains_point?(params[:lat].to_f, params[:lng].to_f)
    end
    boundary = nil unless boundary.is_a?(Boundary)
    if boundary
      redirect_to ward_path(boundary.boundable)
    else
      redirect_to wards_path, alert: "No ward found for that location."
    end
  end

  def news
    @prabhags = @ward.prabhags.order(:number)
    @tweets = @ward.tweets.original.recent
    @tweets = @tweets.where(category: params[:category]) if params[:category].present?
    @tweets = @tweets.limit(20)
    @category_counts = @ward.tweets.original.where.not(category: nil).group(:category).count
    @facility_type_counts = @ward.facilities.group(:facility_type).count
  end

  private

  def set_ward
    # Find ward by slug (using to_param method) or ward_code
    @ward = Ward.all.find { |w| w.to_param == params[:id] } || Ward.find_by!(ward_code: params[:id].upcase)
  end

  def set_variant
    request.variant = :newspaper unless params[:variant] == 'classic'
  end
end
