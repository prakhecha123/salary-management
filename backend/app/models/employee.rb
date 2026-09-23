class Employee < ApplicationRecord
  STATUSES = %w[active terminated].freeze

  has_many :salary_records, -> { order(effective_date: :desc, id: :desc) }, dependent: :destroy

  before_validation :assign_employee_number, on: :create

  validates :employee_number, presence: true, uniqueness: true
  validates :first_name, :last_name, presence: true
  validates :email, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :country, presence: true, inclusion: { in: OrganizationReferenceData::COUNTRIES }
  validates :department, presence: true, inclusion: { in: OrganizationReferenceData::DEPARTMENTS }
  validates :job_title, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :hire_date, presence: true

  scope :in_country, ->(country) { where(country: country) if country.present? }
  scope :in_department, ->(department) { where(department: department) if department.present? }
  scope :with_status, ->(status) { where(status: status) if status.present? }
  scope :search, ->(term) {
    if term.present?
      sanitized = "%#{sanitize_sql_like(term.downcase)}%"
      where(
        "LOWER(first_name) LIKE :term OR LOWER(last_name) LIKE :term " \
          "OR LOWER(email) LIKE :term OR LOWER(employee_number) LIKE :term",
        term: sanitized
      )
    end
  }

  def full_name
    "#{first_name} #{last_name}"
  end

  def current_salary_record
    salary_records.first
  end

  private

  # Derives the next number from the current max rather than a DB sequence.
  # This has a benign race condition under concurrent creates (two requests
  # could compute the same next number); the unique index on employee_number
  # still guarantees no duplicate is ever persisted, it just surfaces as a
  # validation error asking the user to retry. Acceptable here because this
  # app has a single HR Manager creating employees one at a time, not a
  # high-concurrency write path — see docs/trade-offs.md.
  def assign_employee_number
    return if employee_number.present?

    last_number = self.class.maximum(:employee_number)&.delete_prefix("EMP-")&.to_i || 0
    self.employee_number = format("EMP-%05d", last_number + 1)
  end
end
