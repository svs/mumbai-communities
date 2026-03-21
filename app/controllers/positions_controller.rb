class PositionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  def show
    @position = Position.find(params[:id])
    @department = @position.department
    @organisation = @department.organisation
    @ward = @organisation.organisable if @organisation.organisable_type == "Ward"

    # Find other positions held by same person (same name across departments)
    @other_positions = if @position.person_name.present? && @ward
      Position.joins(department: :organisation)
              .where(person_name: @position.person_name)
              .where(organisations: { organisable: @ward })
              .where.not(id: @position.id)
    else
      Position.none
    end

    # News articles from cached profile_data
    @news_articles = @position.profile_data&.dig("news") || []
  end
end
