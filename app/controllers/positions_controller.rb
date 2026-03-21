class PositionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  def show
    @position = Position.find(params[:id])
    @organisation = @position.organisation
    @ward = @organisation.organisable if @organisation.organisable_type == "Ward"

    # Other active positions held by same person
    @other_positions = if @position.person_id.present?
      Position.active.where(person_id: @position.person_id).where.not(id: @position.id).includes(:organisation)
    else
      Position.none
    end
  end
end
