require "rails_helper"

RSpec.describe Employee, type: :model do
  describe "validations" do
    subject { build(:employee) }

    it { is_expected.to be_valid }

    it "requires a unique employee_number" do
      create(:employee, employee_number: "EMP-00001")
      duplicate = build(:employee, employee_number: "EMP-00001", email: "someone.else@example.com")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:employee_number]).to be_present
    end

    it "requires a unique email" do
      create(:employee, email: "taken@example.com")
      duplicate = build(:employee, email: "taken@example.com", employee_number: "EMP-99999")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end

    it "rejects a malformed email" do
      employee = build(:employee, email: "not-an-email")

      expect(employee).not_to be_valid
      expect(employee.errors[:email]).to be_present
    end

    it "rejects a country outside the supported list" do
      employee = build(:employee, country: "Narnia")

      expect(employee).not_to be_valid
      expect(employee.errors[:country]).to be_present
    end

    it "rejects a department outside the supported list" do
      employee = build(:employee, department: "Wizardry")

      expect(employee).not_to be_valid
      expect(employee.errors[:department]).to be_present
    end

    it "rejects an unsupported status" do
      employee = build(:employee, status: "on_vacation_forever")

      expect(employee).not_to be_valid
      expect(employee.errors[:status]).to be_present
    end
  end

  describe "employee_number auto-assignment" do
    it "assigns a sequential EMP-##### number when none is given" do
      create(:employee, employee_number: "EMP-00007")
      employee = build(:employee, employee_number: nil)

      employee.save!

      expect(employee.employee_number).to eq("EMP-00008")
    end

    it "respects an explicitly provided employee_number" do
      employee = build(:employee, employee_number: "EMP-12345")

      employee.save!

      expect(employee.employee_number).to eq("EMP-12345")
    end
  end

  describe "#current_salary_record" do
    it "returns the record with the latest effective_date" do
      employee = create(:employee)
      create(:salary_record, employee: employee, amount: 80_000, effective_date: Date.new(2022, 1, 1))
      latest = create(:salary_record, employee: employee, amount: 95_000, effective_date: Date.new(2024, 1, 1))

      expect(employee.current_salary_record).to eq(latest)
    end

    it "breaks ties on the same effective_date by preferring the most recently created record" do
      employee = create(:employee)
      create(:salary_record, employee: employee, amount: 80_000, effective_date: Date.new(2024, 1, 1))
      correction = create(:salary_record, employee: employee, amount: 82_000, effective_date: Date.new(2024, 1, 1))

      expect(employee.current_salary_record).to eq(correction)
    end

    it "returns nil when the employee has no salary history" do
      employee = create(:employee)

      expect(employee.current_salary_record).to be_nil
    end
  end

  describe ".search" do
    it "matches on first name, last name, email, or employee number, case-insensitively" do
      match = create(:employee, first_name: "Alicia", last_name: "Keys",
        email: "alicia.keys@example.com", employee_number: "EMP-00042")
      create(:employee, first_name: "Bob", last_name: "Smith",
        email: "bob.smith@example.com", employee_number: "EMP-00043")

      expect(Employee.search("alicia")).to contain_exactly(match)
      expect(Employee.search("KEYS")).to contain_exactly(match)
      expect(Employee.search("EMP-00042")).to contain_exactly(match)
    end

    it "returns all employees when the term is blank" do
      create_list(:employee, 2)

      expect(Employee.search(nil).count).to eq(2)
      expect(Employee.search("").count).to eq(2)
    end
  end

  describe "scopes" do
    it "filters by country, department, and status independently" do
      us_engineer = create(:employee, country: "United States", department: "Engineering", status: "active")
      create(:employee, country: "India", department: "Sales", status: "terminated")

      expect(Employee.in_country("United States")).to contain_exactly(us_engineer)
      expect(Employee.in_department("Engineering")).to contain_exactly(us_engineer)
      expect(Employee.with_status("active")).to contain_exactly(us_engineer)
    end
  end
end
