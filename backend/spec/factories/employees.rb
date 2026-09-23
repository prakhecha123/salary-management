FactoryBot.define do
  factory :employee do
    sequence(:employee_number) { |n| format("EMP-%05d", n) }
    first_name { "Jane" }
    last_name { "Doe" }
    sequence(:email) { |n| "jane.doe#{n}@example.com" }
    country { "United States" }
    department { "Engineering" }
    job_title { "Software Engineer" }
    status { "active" }
    hire_date { Date.new(2022, 1, 15) }
  end
end
