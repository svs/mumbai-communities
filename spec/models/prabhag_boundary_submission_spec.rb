require 'rails_helper'

RSpec.describe 'Prabhag Boundary Submission', type: :model do
  let(:user) { users(:user_one) }
  let(:admin) { users(:admin_user) }
  let(:prabhag) do
    Prabhag.create!(
      number: 1001,
      name: "Test Prabhag A1",
      ward_code: "TEST1",
      pdf_url: "https://example.com/test1001.pdf",
      status: "available"
    )
  end

  describe '#submit_boundary!' do
    it 'creates a new pending boundary record' do
      geojson_data = '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}'

      expect {
        prabhag.submit_boundary!(geojson_data, submitted_by: user)
      }.to change { prabhag.boundaries.count }.by(1)

      boundary = prabhag.boundaries.last
      expect(boundary.source_type).to eq('user_submission')
      expect(boundary.year).to eq(2025)
      expect(boundary.status).to eq('pending')
      expect(boundary.is_canonical).to eq(false)
      expect(boundary.submitted_by).to eq(user)
      expect(prabhag.reload.status).to eq('submitted')
    end
  end

  describe 'multiple submissions' do
    it 'creates multiple boundary records' do
      geojson_data1 = '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}'
      geojson_data2 = '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[1,1],[2,1],[2,2],[1,2],[1,1]]]}}'

      prabhag.submit_boundary!(geojson_data1, submitted_by: user)
      expect(prabhag.boundaries.count).to eq(1)

      boundary1 = prabhag.boundaries.last
      boundary1.update!(status: 'rejected', rejection_reason: "Try again")
      prabhag.update!(status: 'rejected', assigned_to: nil)

      prabhag.update!(status: 'assigned', assigned_to: user)
      prabhag.submit_boundary!(geojson_data2, submitted_by: user)

      expect(prabhag.boundaries.count).to eq(2)

      boundary2 = prabhag.boundaries.last
      boundary2.update!(status: 'approved', approved_by: admin, approved_at: Time.current)
      prabhag.update!(status: 'approved')

      boundaries = prabhag.boundaries.order(:created_at)
      expect(boundaries.first.status).to eq('rejected')
      expect(boundaries.last.status).to eq('approved')
    end
  end

  describe 'boundary semantic finders' do
    it 'works with submitted boundaries' do
      expect(prabhag.boundary).to be_nil
      expect(prabhag.has_boundary?).to eq(false)

      geojson_data = '{"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}'
      prabhag.submit_boundary!(geojson_data, submitted_by: user)

      expect(prabhag.approved_boundary).to be_nil
      expect(prabhag.has_boundary?).to eq(true)

      boundary = prabhag.boundaries.last
      boundary.update!(status: 'approved', approved_by: admin, approved_at: Time.current)
      prabhag.update!(status: 'approved')

      boundary = prabhag.approved_boundary
      expect(boundary).not_to be_nil
      expect(boundary.status).to eq('approved')
      expect(boundary).to eq(prabhag.boundary)
    end
  end
end
