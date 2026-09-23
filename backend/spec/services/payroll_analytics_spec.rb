require "rails_helper"

RSpec.describe PayrollAnalytics do
  let!(:usd) { create(:exchange_rate, currency: "USD", rate_to_usd: 1.0) }
  let!(:inr) { create(:exchange_rate, :inr, rate_to_usd: 0.01) }

  describe ".by_country" do
    it "aggregates headcount and payroll cost per country, converted to USD" do
      us_employee = create(:employee, country: "United States")
      create(:salary_record, employee: us_employee, amount: 100_000, currency: "USD",
        effective_date: Date.new(2023, 1, 1))

      india_employee = create(:employee, country: "India")
      create(:salary_record, employee: india_employee, amount: 2_000_000, currency: "INR",
        effective_date: Date.new(2023, 1, 1))

      results = described_class.by_country.index_by { |row| row[:country] }

      expect(results["United States"][:headcount]).to eq(1)
      expect(results["United States"][:total_payroll_usd]).to eq(100_000.0)

      expect(results["India"][:headcount]).to eq(1)
      expect(results["India"][:total_payroll_usd]).to eq(20_000.0)
    end

    it "uses only each employee's most recent salary record" do
      employee = create(:employee, country: "United States")
      create(:salary_record, employee: employee, amount: 80_000, currency: "USD",
        effective_date: Date.new(2021, 1, 1))
      create(:salary_record, employee: employee, amount: 110_000, currency: "USD",
        effective_date: Date.new(2023, 1, 1))

      result = described_class.by_country.find { |row| row[:country] == "United States" }

      expect(result[:total_payroll_usd]).to eq(110_000.0)
      expect(result[:headcount]).to eq(1)
    end

    it "excludes terminated employees from payroll cost" do
      active = create(:employee, country: "United States", status: "active")
      create(:salary_record, employee: active, amount: 100_000, currency: "USD")

      terminated = create(:employee, country: "United States", status: "terminated",
        employee_number: "EMP-90000", email: "left@example.com")
      create(:salary_record, employee: terminated, amount: 500_000, currency: "USD")

      result = described_class.by_country.find { |row| row[:country] == "United States" }

      expect(result[:headcount]).to eq(1)
      expect(result[:total_payroll_usd]).to eq(100_000.0)
    end
  end

  describe ".overall" do
    it "returns a single aggregate row across the whole org" do
      first = create(:employee, employee_number: "EMP-00001", email: "one@example.com")
      create(:salary_record, employee: first, amount: 100_000, currency: "USD")

      second = create(:employee, employee_number: "EMP-00002", email: "two@example.com")
      create(:salary_record, employee: second, amount: 200_000, currency: "USD")

      result = described_class.overall

      expect(result[:headcount]).to eq(2)
      expect(result[:total_payroll_usd]).to eq(300_000.0)
      expect(result[:average_salary_usd]).to eq(150_000.0)
    end
  end

  describe "median_salary_usd" do
    def create_employee_with_salary(amount, number:)
      employee = create(:employee, employee_number: number, email: "#{number}@example.com")
      create(:salary_record, employee: employee, amount: amount, currency: "USD")
      employee
    end

    it "takes the middle value for an odd number of employees, distinct from the mean" do
      [100_000, 200_000, 900_000].each_with_index do |amount, i|
        create_employee_with_salary(amount, number: "EMP-0000#{i}")
      end

      result = described_class.overall

      expect(result[:median_salary_usd]).to eq(200_000.0)
      expect(result[:average_salary_usd]).to eq(400_000.0)
    end

    it "averages the two middle values for an even number of employees" do
      [100_000, 200_000, 300_000, 900_000].each_with_index do |amount, i|
        create_employee_with_salary(amount, number: "EMP-0000#{i}")
      end

      result = described_class.overall

      expect(result[:median_salary_usd]).to eq(250_000.0)
      expect(result[:average_salary_usd]).to eq(375_000.0)
    end

    it "is the single employee's salary for a group of one" do
      create_employee_with_salary(123_000, number: "EMP-00001")

      result = described_class.overall

      expect(result[:median_salary_usd]).to eq(123_000.0)
    end

    it "computes medians independently per country" do
      us = create(:employee, country: "United States", employee_number: "EMP-00001", email: "us@example.com")
      create(:salary_record, employee: us, amount: 100_000, currency: "USD")

      india_low = create(:employee, country: "India", employee_number: "EMP-00002", email: "i1@example.com")
      create(:salary_record, employee: india_low, amount: 1_000_000, currency: "INR")
      india_high = create(:employee, country: "India", employee_number: "EMP-00003", email: "i2@example.com")
      create(:salary_record, employee: india_high, amount: 3_000_000, currency: "INR")

      results = described_class.by_country.index_by { |row| row[:country] }

      expect(results["United States"][:median_salary_usd]).to eq(100_000.0)
      expect(results["India"][:median_salary_usd]).to eq(20_000.0)
    end
  end
end
