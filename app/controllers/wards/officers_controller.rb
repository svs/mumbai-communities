module Wards
  class OfficersController < ApplicationController
    skip_before_action :authenticate_user!
    skip_forgery_protection only: [:create]

    before_action :set_ward

    def create
      authenticate_api_key!
      return if performed?

      officers = Array(params[:officers])
      result = import_officers(officers)

      render json: result
    end

    private

    def set_ward
      @ward = Ward.all.find { |w| w.to_param == params[:ward_id] } || Ward.find_by!(ward_code: params[:ward_id].upcase)
    end

    def authenticate_api_key!
      token = request.headers["Authorization"]&.remove("Bearer ")
      head :unauthorized unless token.present? && ActiveSupport::SecurityUtils.secure_compare(token, ENV.fetch("TWEETS_API_KEY"))
    end

    def import_officers(officers_data)
      ward_org = Organisation.find_or_create_by!(organisable: @ward, org_type: "ward") do |org|
        org.name = "Ward #{@ward.ward_code}"
      end

      imported = 0
      updated = 0
      transferred = 0
      errors = []

      officers_data.each do |officer|
        officer = officer.permit!.to_h if officer.respond_to?(:permit!)

        next unless officer["designation"].present?

        section = officer["section"] || "Ward Office"
        dept = Department.find_or_create_by!(organisation: ward_org, name: section)

        # Find existing active position by email or designation
        existing = nil
        if officer["email"].present?
          existing = Position.joins(:department)
            .where(departments: { organisation_id: ward_org.id })
            .where(email: officer["email"], active: true)
            .first
        end
        existing ||= Position.where(department: dept, designation: officer["designation"], active: true).first

        if existing
          if existing.person_name == officer["person_name"] || officer["person_name"].blank?
            # Same person or no name — update contact info
            attrs = {}
            attrs[:phone] = officer["phone"] if officer["phone"].present?
            attrs[:email] = officer["email"] if officer["email"].present? && existing.email.blank?
            attrs[:person_name] = officer["person_name"] if officer["person_name"].present? && existing.person_name.blank?
            attrs[:linkedin_url] = officer["linkedin_url"] if officer["linkedin_url"].present?
            attrs[:twitter_handle] = officer["twitter_handle"] if officer["twitter_handle"].present?
            attrs[:bio] = officer["bio"] if officer["bio"].present?
            attrs[:profile_data] = officer["profile_data"] if officer["profile_data"].present?
            existing.update!(attrs) if attrs.any?
            updated += 1
          else
            # Transfer!
            existing.update!(active: false, ended_on: Date.current)
            Position.create!(
              department: dept,
              designation: officer["designation"],
              person_name: officer["person_name"],
              phone: officer["phone"],
              email: officer["email"],
              level: officer["level"] || "mid",
              linkedin_url: officer["linkedin_url"],
              twitter_handle: officer["twitter_handle"],
              bio: officer["bio"],
              profile_data: officer["profile_data"],
              active: true,
              started_on: Date.current
            )
            transferred += 1
          end
        else
          Position.create!(
            department: dept,
            designation: officer["designation"],
            person_name: officer["person_name"],
            phone: officer["phone"],
            email: officer["email"],
            level: officer["level"] || "mid",
            linkedin_url: officer["linkedin_url"],
            twitter_handle: officer["twitter_handle"],
            bio: officer["bio"],
            profile_data: officer["profile_data"],
            active: true,
            started_on: Date.current
          )
          imported += 1
        end
      rescue => e
        errors << { designation: officer["designation"], error: e.message }
      end

      {
        ward: @ward.ward_code,
        imported: imported,
        updated: updated,
        transferred: transferred,
        errors: errors
      }
    end
  end
end
