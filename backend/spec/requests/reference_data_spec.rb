require "rails_helper"

RSpec.describe "Reference Data API", type: :request do
  describe "GET /reference_data" do
    it "returns the supported countries, departments, currencies, and statuses" do
      get "/reference_data"

      json = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json["countries"]).to include("United States", "India")
      expect(json["departments"]).to include("Engineering")
      expect(json["currencies"]).to include("USD", "INR")
      expect(json["statuses"]).to eq(["active", "terminated"])
    end
  end
end
