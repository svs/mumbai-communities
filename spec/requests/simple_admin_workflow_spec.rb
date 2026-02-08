require 'rails_helper'

RSpec.describe "Simple Admin Workflow", type: :request do
  let(:admin) { users(:admin_2) }
  let(:user) { users(:user_one) }
  let(:prabhag) { prabhags(:prabhag_one) }
  let(:geojson_data) { '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[72.8777,19.0760],[72.8778,19.0760],[72.8778,19.0761],[72.8777,19.0761],[72.8777,19.0760]]]},"properties":{}}' }

  describe "complete admin workflow: submit -> approve" do
    it "allows admin to approve submitted boundary" do
      prabhag.update!(status: 'submitted', assigned_to: user)
      boundary = prabhag.boundaries.create!(
        geojson: geojson_data,
        source_type: 'user_submission',
        year: 2025,
        status: 'pending',
        submitted_by: user
      )

      sign_in admin
      get admin_prabhag_path(prabhag)
      expect(response).to have_http_status(:success)

      post approve_admin_boundary_path(boundary)
      expect(response).to have_http_status(:redirect)

      boundary.reload
      prabhag.reload

      expect(boundary.status).to eq('approved')
      expect(boundary.approved_by).to eq(admin)
      expect(prabhag.status).to eq('approved')
    end
  end

  describe "complete admin workflow: submit -> reject" do
    it "allows admin to reject submitted boundary" do
      prabhag.update!(status: 'submitted', assigned_to: user)
      boundary = prabhag.boundaries.create!(
        geojson: geojson_data,
        source_type: 'user_submission',
        year: 2025,
        status: 'pending',
        submitted_by: user
      )

      sign_in admin
      post reject_admin_boundary_path(boundary), params: { rejection_reason: "Please improve" }
      expect(response).to have_http_status(:redirect)

      boundary.reload
      prabhag.reload

      expect(boundary.status).to eq('rejected')
      expect(boundary.rejection_reason).to eq("Please improve")
      expect(prabhag.status).to eq('rejected')
      expect(prabhag.assigned_to).to be_nil
    end
  end

  describe "admin access" do
    it "admin can access index page" do
      sign_in admin

      get admin_prabhags_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Admin Panel')
    end

    it "non-admin cannot access admin functions" do
      sign_in user

      get admin_prabhags_path
      expect(response).to have_http_status(:redirect)

      get admin_prabhag_path(prabhag)
      expect(response).to have_http_status(:redirect)
    end
  end
end
