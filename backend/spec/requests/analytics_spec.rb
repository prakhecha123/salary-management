require "rails_helper"

RSpec.describe "Analytics API", type: :request do
  describe "GET /analytics/overview" do
    it "returns overall, by-country, and by-department breakdowns" do
      create(:exchange_rate)
      employee = create(:employee, employee_number: "EMP-00001", email: "e@example.com",
        country: "United States", department: "Engineering")
      create(:salary_record, employee: employee, amount: 120_000, currency: "USD")

      get "/analytics/overview"

      json = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json["overall"]["headcount"]).to eq(1)
      expect(json["overall"]["median_salary_usd"]).to eq(120_000.0)
      expect(json["by_country"].first["country"]).to eq("United States")
      expect(json["by_country"].first["median_salary_usd"]).to eq(120_000.0)
      expect(json["by_department"].first["department"]).to eq("Engineering")
    end
  end
end
