# Seeds 10,000 employees with realistic salary bands and multi-year salary
# history. Uses bulk `insert_all!` rather than 10,000 individual `.create`
# calls (which would run every validation/callback per row and take minutes)
# — this runs in seconds. Bypassing callbacks means this script is
# responsible for satisfying every constraint the models normally enforce:
# unique employee_number/email, valid country/department/currency, positive
# amounts.

require "faker"

EMPLOYEE_COUNT = 10_000
BATCH_SIZE = 1_000

EXCHANGE_RATES = {
  "USD" => 1.0,
  "INR" => 0.012,
  "GBP" => 1.27,
  "EUR" => 1.09,
  "CAD" => 0.73,
  "AUD" => 0.66,
  "SGD" => 0.74
}.freeze

# Illustrative, not sourced from live market data (see docs/trade-offs.md).
# Relative to a US=1.0 baseline; reflects that a given role is generally paid
# less in nominal USD terms in lower-cost markets, which is why an MNC pays
# in local currency scaled to local market rate rather than converting a US
# salary 1:1.
COUNTRY_COST_OF_LIVING = {
  "United States" => 1.00,
  "United Kingdom" => 0.85,
  "Germany" => 0.80,
  "France" => 0.78,
  "Canada" => 0.90,
  "Australia" => 0.95,
  "Singapore" => 0.90,
  "India" => 0.35
}.freeze

# Employees per country, roughly proportional to where a real org like this
# would concentrate headcount (larger US and India offices).
COUNTRY_WEIGHTS = {
  "United States" => 30,
  "India" => 25,
  "United Kingdom" => 10,
  "Canada" => 8,
  "Germany" => 8,
  "France" => 6,
  "Australia" => 7,
  "Singapore" => 6
}.freeze

# Four seniority levels per department: job titles in ascending order. Level
# index also drives the salary multiplier below.
JOB_LEVELS = {
  "Engineering" => ["Software Engineer I", "Software Engineer II", "Senior Software Engineer", "Engineering Manager"],
  "Sales" => ["Sales Associate", "Account Executive", "Senior Account Executive", "Sales Manager"],
  "Marketing" => ["Marketing Associate", "Marketing Specialist", "Senior Marketing Specialist", "Marketing Manager"],
  "Finance" => ["Financial Analyst", "Senior Financial Analyst", "Finance Manager", "Finance Director"],
  "Human Resources" => ["HR Coordinator", "HR Generalist", "Senior HR Generalist", "HR Manager"],
  "Operations" => ["Operations Associate", "Operations Analyst", "Senior Operations Analyst", "Operations Manager"],
  "Customer Support" => ["Support Associate", "Support Specialist", "Senior Support Specialist", "Support Team Lead"],
  "Product" => ["Associate Product Manager", "Product Manager", "Senior Product Manager", "Director of Product"],
  "Legal" => ["Legal Associate", "Corporate Counsel", "Senior Counsel", "Legal Director"],
  "Design" => ["Junior Product Designer", "Product Designer", "Senior Product Designer", "Design Manager"]
}.freeze

DEPARTMENT_BASE_SALARY_USD = {
  "Engineering" => 78_000,
  "Sales" => 60_000,
  "Marketing" => 58_000,
  "Finance" => 65_000,
  "Human Resources" => 52_000,
  "Operations" => 54_000,
  "Customer Support" => 42_000,
  "Product" => 82_000,
  "Legal" => 75_000,
  "Design" => 65_000
}.freeze

LEVEL_MULTIPLIERS = [1.0, 1.3, 1.7, 2.2].freeze

def weighted_sample(weights)
  total = weights.values.sum
  target = rand(total)
  cumulative = 0

  weights.each do |value, weight|
    cumulative += weight
    return value if target < cumulative
  end
end

def annual_salary_usd(department, level_index, country)
  base = DEPARTMENT_BASE_SALARY_USD.fetch(department)
  level_multiplier = LEVEL_MULTIPLIERS[level_index]
  cost_of_living = COUNTRY_COST_OF_LIVING.fetch(country)
  variance = rand(0.92..1.08) # some spread within a level, like real comp bands

  (base * level_multiplier * cost_of_living * variance).round(2)
end

def usd_to_local(amount_usd, currency)
  (amount_usd / EXCHANGE_RATES.fetch(currency)).round(2)
end

puts "Clearing existing data..."
SalaryRecord.delete_all
Employee.delete_all
ExchangeRate.delete_all

puts "Seeding exchange rates..."
now = Time.current
ExchangeRate.insert_all!(
  EXCHANGE_RATES.map { |currency, rate| { currency: currency, rate_to_usd: rate, created_at: now, updated_at: now } }
)

puts "Generating #{EMPLOYEE_COUNT} employees..."
today = Date.current
earliest_hire_date = today - 8.years

employee_rows = []
job_level_by_row = [] # parallel array: [department, level_index, country, hire_date] per employee

EMPLOYEE_COUNT.times do |i|
  first_name = Faker::Name.first_name
  last_name = Faker::Name.last_name
  country = weighted_sample(COUNTRY_WEIGHTS)
  department = JOB_LEVELS.keys.sample
  level_index = rand(JOB_LEVELS[department].length)
  job_title = JOB_LEVELS[department][level_index]
  status = rand < 0.92 ? "active" : "terminated"
  hire_date = Faker::Date.between(from: earliest_hire_date, to: today - 30)

  employee_rows << {
    employee_number: format("EMP-%05d", i + 1),
    first_name: first_name,
    last_name: last_name,
    email: "#{first_name.downcase}.#{last_name.downcase}#{i + 1}@acmecorp.example.com",
    country: country,
    department: department,
    job_title: job_title,
    status: status,
    hire_date: hire_date,
    created_at: now,
    updated_at: now
  }
  job_level_by_row << { department: department, level_index: level_index, country: country, hire_date: hire_date }
end

employee_rows.each_slice(BATCH_SIZE) { |batch| Employee.insert_all!(batch) }

puts "Looking up generated employee ids..."
employee_id_by_number = Employee.pluck(:employee_number, :id).to_h

puts "Generating salary history..."
salary_rows = []

employee_rows.each_with_index do |row, i|
  employee_id = employee_id_by_number.fetch(row[:employee_number])
  meta = job_level_by_row[i]
  currency = OrganizationReferenceData.default_currency_for(meta[:country])

  years_employed = ((today - meta[:hire_date]) / 365).to_i
  num_raises = [years_employed, 3].min

  starting_salary_usd = annual_salary_usd(meta[:department], meta[:level_index], meta[:country])
  current_salary_usd = starting_salary_usd

  salary_rows << {
    employee_id: employee_id,
    amount: usd_to_local(starting_salary_usd, currency),
    currency: currency,
    effective_date: meta[:hire_date],
    reason: "Initial offer",
    created_at: now,
    updated_at: now
  }

  num_raises.times do |raise_number|
    current_salary_usd = (current_salary_usd * rand(1.03..1.08)).round(2)
    # `years_employed` above approximates a year as 365 days; calendar-aware
    # `.years` arithmetic can add 366 across a leap day, so the naive
    # hire_date + N.years can land one day past `today` right at the
    # boundary (e.g. hired 2023-09-24, 1095 days elapsed reads as exactly 3
    # years, but 2023-09-24 + 3.years is 2026-09-24 because 2024 was a leap
    # year — one day ahead of `today`). Clamping is the fix, not a more
    # precise elapsed-time calculation: a salary record dated "today" for an
    # employee whose true 3-year mark is tomorrow is a fine approximation
    # for seed data; a future-dated salary record is not.
    effective_date = [meta[:hire_date] + (raise_number + 1).years, today].min
    salary_rows << {
      employee_id: employee_id,
      amount: usd_to_local(current_salary_usd, currency),
      currency: currency,
      effective_date: effective_date,
      reason: "Annual raise",
      created_at: now,
      updated_at: now
    }
  end
end

salary_rows.each_slice(BATCH_SIZE) { |batch| SalaryRecord.insert_all!(batch) }

puts "Done: #{Employee.count} employees, #{SalaryRecord.count} salary records, #{ExchangeRate.count} exchange rates."
