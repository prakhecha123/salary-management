# Plain serialization helpers rather than a gem (e.g. ActiveModel::Serializer):
# the API has exactly two employee shapes (list row, full detail) and neither
# is likely to grow much, so a dependency for this would be more machinery
# than the problem needs.
class EmployeeSerializer
  def self.summary(employee)
    current = employee.current_salary_record

    {
      id: employee.id,
      employee_number: employee.employee_number,
      full_name: employee.full_name,
      email: employee.email,
      country: employee.country,
      department: employee.department,
      job_title: employee.job_title,
      status: employee.status,
      hire_date: employee.hire_date,
      current_salary: current && salary_summary(current)
    }
  end

  def self.detail(employee)
    summary(employee).merge(
      first_name: employee.first_name,
      last_name: employee.last_name,
      salary_history: employee.salary_records.map { |record| salary_summary(record) }
    )
  end

  def self.salary_summary(salary_record)
    {
      id: salary_record.id,
      amount: salary_record.amount.to_f,
      currency: salary_record.currency,
      amount_usd: salary_record.amount_in_usd&.to_f,
      effective_date: salary_record.effective_date,
      reason: salary_record.reason
    }
  end
end
