class WardsController < ApplicationController
  before_action :set_ward, only: [:show]

  def index
    @wards = Ward.order(:ward_code)
    @total_wards = @wards.count
    @geocoded_wards = @wards.geocoded.count
    @total_tickets = Ticket.count
    @open_tickets = Ticket.open.count
    @overdue_tickets = Ticket.overdue.count
  end

  def show
    @prabhags = @ward.prabhags.order(:number)
    @tickets = @ward.tickets.includes(:assigned_to).order(:status, :priority, :due_date)
    @open_tickets = @tickets.where(status: ['open', 'assigned', 'in_progress'])
    @completed_tickets = @tickets.completed
  end

  private

  def set_ward
    @ward = Ward.find_by!(ward_code: params[:id])
  end
end
