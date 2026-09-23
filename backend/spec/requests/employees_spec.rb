require "rails_helper"

RSpec.describe "Employees API", type: :request do
  before { create(:exchange_rate) }

  describe "GET /employees" do
    it "returns a paginated list ordered by name" do
      zack = create(:employee, first_name: "Zack", last_name: "Young",
        employee_number: "EMP-00001", email: "zack@example.com")
      create(:salary_record, employee: zack)
      amy = create(:employee, first_name: "Amy", last_name: "Adams",
        employee_number: "EMP-00002", email: "amy@example.com")
      create(:salary_record, employee: amy)

      get "/employees"

      json = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(json["employees"].map { |e| e["full_name"] }).to eq(["Amy Adams", "Zack Young"])
      expect(json["meta"]).to include("total_count" => 2, "page" => 1)
    end

    it "includes each employee's current salary in USD" do
      employee = create(:employee, employee_number: "EMP-00001", email: "e@example.com")
      create(:salary_record, employee: employee, amount: 100_000, currency: "USD")

      get "/employees"

      salary = response.parsed_body["employees"].first["current_salary"]
      expect(salary["amount"]).to eq(100_000.0)
      expect(salary["amount_usd"]).to eq(100_000.0)
    end

    it "filters by country, department, status, and search term" do
      create(:employee, employee_number: "EMP-00001", email: "a@example.com",
        first_name: "Match", country: "India", department: "Sales", status: "active")
      create(:employee, employee_number: "EMP-00002", email: "b@example.com",
        first_name: "Other", country: "United States", department: "Engineering", status: "terminated")

      get "/employees", params: { country: "India", department: "Sales", status: "active", q: "match" }

      names = response.parsed_body["employees"].map { |e| e["full_name"] }
      expect(names).to eq(["Match Doe"])
    end

    it "clamps per_page to the configured maximum" do
      create_list(:employee, 3)

      get "/employees", params: { per_page: 10_000 }

      expect(response.parsed_body["meta"]["per_page"]).to eq(EmployeesController::MAX_PER_PAGE)
    end
  end

  describe "GET /employees/:id" do
    it "returns full salary history ordered most-recent-first" do
      employee = create(:employee, employee_number: "EMP-00001", email: "e@example.com")
      create(:salary_record, employee: employee, amount: 80_000, effective_date: Date.new(2021, 1, 1))
      create(:salary_record, employee: employee, amount: 95_000, effective_date: Date.new(2023, 1, 1))

      get "/employees/#{employee.id}"

      history = response.parsed_body["salary_history"]
      expect(history.map { |r| r["amount"] }).to eq([95_000.0, 80_000.0])
    end

    it "returns 404 for an unknown employee" do
      get "/employees/999999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /employees" do
    it "creates an employee with its initial salary record in one request" do
      post "/employees", params: {
        employee: {
          first_name: "New", last_name: "Hire", email: "new.hire@example.com",
          country: "United States", department: "Engineering",
          job_title: "Engineer", status: "active", hire_date: "2026-01-01"
        },
        initial_salary: { amount: 100_000, currency: "USD", effective_date: "2026-01-01", reason: "Initial offer" }
      }

      expect(response).to have_http_status(:created)
      json = response.parsed_body
      expect(json["employee_number"]).to eq("EMP-00001")
      expect(json["salary_history"].first["amount"]).to eq(100_000.0)
      expect(Employee.count).to eq(1)
    end

    it "rolls back the employee if the initial salary is invalid" do
      post "/employees", params: {
        employee: {
          first_name: "New", last_name: "Hire", email: "new.hire@example.com",
          country: "United States", department: "Engineering",
          job_title: "Engineer", status: "active", hire_date: "2026-01-01"
        },
        initial_salary: { amount: -1, currency: "USD", effective_date: "2026-01-01" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Employee.count).to eq(0)
    end

    it "rejects an invalid employee" do
      post "/employees", params: {
        employee: { first_name: "", last_name: "Hire", email: "not-an-email",
                    country: "Nowhere", department: "Engineering",
                    job_title: "Engineer", status: "active", hire_date: "2026-01-01" },
        initial_salary: { amount: 100_000, currency: "USD", effective_date: "2026-01-01" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Employee.count).to eq(0)
    end
  end

  describe "PATCH /employees/:id" do
    it "updates employee attributes without touching salary history" do
      employee = create(:employee, employee_number: "EMP-00001", email: "e@example.com", job_title: "Engineer I")
      create(:salary_record, employee: employee)

      patch "/employees/#{employee.id}", params: { employee: { job_title: "Engineer II" } }

      expect(response).to have_http_status(:ok)
      expect(employee.reload.job_title).to eq("Engineer II")
      expect(employee.salary_records.count).to eq(1)
    end
  end
end
