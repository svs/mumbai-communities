require 'rails_helper'

RSpec.describe "Prabhags", type: :request do
  let(:ward) { wards(:ward_A) }
  let(:prabhag) { prabhags(:prabhag_A_225) }

  describe "GET /prabhags/:id (show)" do
    it "renders successfully" do
      get prabhag_path(prabhag)
      expect(response).to have_http_status(:ok)
    end

    it "shows breadcrumb navigation" do
      get prabhag_path(prabhag)
      expect(response.body).to include("Home")
      expect(response.body).to include("Wards")
      expect(response.body).to include("Ward A")
      expect(response.body).to include("Prabhag 225")
    end

    it "shows the prabhag number in the heading" do
      get prabhag_path(prabhag)
      assert_select "h1", text: /Prabhag 225/
    end

    it "links back to the ward page" do
      get prabhag_path(prabhag)
      assert_select "a[href='#{ward_path(ward)}']"
    end

    it "shows the MCGM PDF reference link" do
      get prabhag_path(prabhag)
      assert_select "a[href='#{prabhag.pdf_url}']"
    end

    it "shows a large map container" do
      get prabhag_path(prabhag)
      assert_select "[data-controller='leaflet-map']"
    end

    it "shows boundary history when boundaries exist" do
      get prabhag_path(prabhag)
      expect(response.body).to include("Boundary History")
    end

    # Phase 1: things that should NOT be on this page
    it "does not show community action buttons" do
      get prabhag_path(prabhag)
      assert_select "button", text: /Report Issue/, count: 0
      expect(response.body).not_to include("cursor-not-allowed")
    end

    it "does not show community stats section" do
      get prabhag_path(prabhag)
      expect(response.body).not_to include("Community Stats")
      expect(response.body).not_to include("Active Neighbors")
      expect(response.body).not_to include("Resolution Rate")
    end

    it "does not show recent issues section" do
      get prabhag_path(prabhag)
      expect(response.body).not_to include("Recent Issues")
      expect(response.body).not_to include("Recent Activity")
    end

    it "does not have dead placeholder links" do
      get prabhag_path(prabhag)
      expect(response.body).not_to include("Election Results")
      expect(response.body).not_to include("Demographics")
    end

    it "does not show redundant prabhag information section" do
      get prabhag_path(prabhag)
      assert_select "h2", text: "Prabhag Information", count: 0
    end

    it "does not show representatives section" do
      get prabhag_path(prabhag)
      expect(response.body).not_to include("REPRESENTATIVES")
    end

    it "embeds the MCGM PDF inline for reference" do
      get prabhag_path(prabhag)
      assert_select "object[data*='prabhag_pdfs'], iframe[src*='prabhag_pdfs'], embed[src*='prabhag_pdfs']"
    end

    it "shows POIs or facility info for mapped prabhags" do
      get prabhag_path(prabhag)
      # Mapped prabhags show "What's here" (POIs) or a message about facility loading
      expect(response.body).to include("What's here").or include("Facility data").or include("OpenStreetMap")
    end
  end
end
