require "rails_helper"

RSpec.describe "Salary Records API", type: :request do
  before { create(:exchange_rate) }

  describe "POST /employees/:employee_id/salary_records" do
    it "adds a new salary record and it becomes the employee's current salary" do
      employee = create(:employee, employee_number: "EMP-00001", email: "e@example.com")
      create(:salary_record, employee: employee, amount: 90_000, effective_date: Date.new(2023, 1, 1))

      post "/employees/#{employee.id}/salary_records", params: {
        salary_record: { amount: 105_000, currency: "USD", effective_date: Date.new(2024, 1, 1), reason: "Annual raise" }
      }

      expect(response).to have_http_status(:created)
      expect(employee.reload.current_salary_record.amount).to eq(105_000)
      expect(employee.salary_records.count).to eq(2)
    end

    it "rejects an invalid salary record and leaves history unchanged" do
      employee = create(:employee, employee_number: "EMP-00001", email: "e@example.com")
      create(:salary_record, employee: employee, amount: 90_000)

      post "/employees/#{employee.id}/salary_records", params: {
        salary_record: { amount: -5, currency: "USD", effective_date: Date.new(2024, 1, 1) }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(employee.salary_records.count).to eq(1)
    end

    it "returns 404 for an unknown employee" do
      post "/employees/999999/salary_records", params: {
        salary_record: { amount: 100_000, currency: "USD", effective_date: Date.new(2024, 1, 1) }
      }

      expect(response).to have_http_status(:not_found)
    end
  end
end
