require 'rails_helper'

RSpec.describe "Admin::Boundaries", type: :request do
  let(:admin_user) { users(:admin_2) }
  let(:regular_user) { users(:svs_3) }
  let(:ward) { Ward.find(21) }
  let(:prabhag) { prabhags(:prabhag_A_225) }
  let(:existing_ward_boundary) { boundaries(:boundary_ward_21_1) }

  let(:ward_boundary) do
    Boundary.create!(
      boundable: ward,
      geojson: existing_ward_boundary.geojson,
      source_type: 'user_submission',
      status: 'pending',
      submitted_by: regular_user
    )
  end

  let(:prabhag_boundary) do
    Boundary.create!(
      boundable: prabhag,
      geojson: '{"type":"Polygon","coordinates":[[[72.8266139,19.0192703],[72.8268942,19.0194151],[72.8266139,19.0192703]]]}',
      source_type: 'user_submission',
      status: 'pending',
      submitted_by: regular_user
    )
  end

  describe "POST /admin/boundaries/:id/approve" do
    context "authentication and authorization" do
      it "requires authentication" do
        post approve_admin_boundary_path(ward_boundary)
        expect(response).to redirect_to(new_user_session_path)
      end

      it "requires admin privileges" do
        sign_in regular_user
        post approve_admin_boundary_path(ward_boundary)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('Access denied. Admin privileges required.')
      end
    end

    context "as admin" do
      before { sign_in admin_user }

      it "approves a pending ward boundary" do
        expect(ward_boundary.status).to eq('pending')

        post approve_admin_boundary_path(ward_boundary)

        ward_boundary.reload
        expect(ward_boundary.status).to eq('approved')
        expect(ward_boundary.approved_by).to eq(admin_user)
        expect(ward_boundary.approved_at).not_to be_nil
        expect(response).to redirect_to(admin_boundaries_path)
        expect(flash[:notice]).to eq('Boundary approved successfully!')
      end

      it "sets approval timestamp" do
        freeze_time = Time.current

        travel_to freeze_time do
          post approve_admin_boundary_path(ward_boundary)
        end

        ward_boundary.reload
        expect(ward_boundary.approved_at.to_i).to eq(freeze_time.to_i)
      end
    end
  end

  describe "POST /admin/boundaries/:id/reject" do
    before { sign_in admin_user }

    it "rejects a pending boundary with default reason" do
      post reject_admin_boundary_path(ward_boundary)

      ward_boundary.reload
      expect(ward_boundary.status).to eq('rejected')
      expect(ward_boundary.approved_by).to eq(admin_user)
      expect(ward_boundary.rejection_reason).to eq("Rejected by admin")
    end

    it "rejects with custom reason" do
      custom_reason = "Boundary is inaccurate"

      post reject_admin_boundary_path(prabhag_boundary), params: { rejection_reason: custom_reason }

      prabhag_boundary.reload
      expect(prabhag_boundary.status).to eq('rejected')
      expect(prabhag_boundary.rejection_reason).to eq(custom_reason)
    end
  end

  describe "DELETE /admin/boundaries/:id" do
    before { sign_in admin_user }

    it "deletes a ward boundary" do
      boundary_to_delete = ward_boundary

      expect {
        delete admin_boundary_path(boundary_to_delete)
      }.to change { Boundary.count }.by(-1)

      expect(response).to redirect_to(admin_boundaries_path)
      expect(flash[:notice]).to eq('Boundary deleted successfully.')
    end
  end

  describe "GET /admin/prabhags/:prabhag_id/boundaries/:id/edit" do
    before { sign_in admin_user }

    it "gets boundary edit page" do
      get edit_admin_prabhag_boundary_path(prabhag, prabhag_boundary)

      expect(response).to have_http_status(:success)
      expect(response.body).to include("data-controller='boundary-tracer'")
      expect(response.body).to include('Update Boundary')
    end

    it "pre-populates boundary data" do
      get edit_admin_prabhag_boundary_path(prabhag, prabhag_boundary)

      expect(response).to have_http_status(:success)
      boundary_geometry = JSON.parse(prabhag_boundary.geojson)["geometry"]
      expect(response.body).to include(boundary_geometry.to_json)
    end
  end

  describe "PATCH /admin/prabhags/:prabhag_id/boundaries/:id" do
    before { sign_in admin_user }

    it "updates boundary with admin edits" do
      new_geojson = '{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[72.8280000,19.0200000],[72.8285000,19.0205000],[72.8290000,19.0200000],[72.8280000,19.0200000]]]}}'

      patch admin_prabhag_boundary_path(prabhag, prabhag_boundary), params: {
        boundary: { geojson: new_geojson }
      }

      prabhag_boundary.reload
      expect(prabhag_boundary.geojson).to eq(new_geojson)
      expect(response).to redirect_to(admin_prabhag_path(prabhag))
      expect(flash[:notice]).to eq('Boundary updated successfully.')
    end

    it "tracks edited_by when admin edits boundary" do
      expect(prabhag_boundary.edited_by).to be_nil

      new_geojson = '{"type":"Feature","properties":{},"geometry":{"type":"Polygon","coordinates":[[[72.8280000,19.0200000],[72.8285000,19.0205000],[72.8290000,19.0200000],[72.8280000,19.0200000]]]}}'

      patch admin_prabhag_boundary_path(prabhag, prabhag_boundary), params: {
        boundary: { geojson: new_geojson }
      }

      prabhag_boundary.reload
      expect(prabhag_boundary.edited_by).to eq(admin_user)
    end
  end
end
