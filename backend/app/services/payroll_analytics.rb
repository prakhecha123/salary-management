# Answers the "how does the org pay people" questions the HR Manager needs:
# headcount, total payroll cost, and salary distribution, broken down by
# country or department, in a single common currency (USD).
#
# Implemented as one SQL query per breakdown rather than loading records into
# Ruby: "current salary per employee" (a window function over salary_records,
# since salary history means an employee can have many rows) joined to
# exchange_rates for conversion, aggregated in the database. This scales to
# 10,000+ employees without pulling every salary record into memory just to
# find each employee's latest one.
#
# `group_column` is always one of two hardcoded, non-user-supplied SQL
# fragments (never request input), so string interpolation here does not
# introduce a SQL injection risk.
class PayrollAnalytics
  CURRENT_SALARIES_CTE = <<~SQL.squish
    WITH current_salaries AS (
      SELECT
        employee_id,
        amount,
        currency,
        ROW_NUMBER() OVER (
          PARTITION BY employee_id
          ORDER BY effective_date DESC, id DESC
        ) AS rank_within_employee
      FROM salary_records
    )
  SQL

  def self.by_country
    aggregate(group_column: "employees.country", label: :country)
  end

  def self.by_department
    aggregate(group_column: "employees.department", label: :department)
  end

  def self.overall
    aggregate(group_column: nil, label: nil).first
  end

  def self.aggregate(group_column:, label:)
    select_group = group_column ? "#{group_column} AS group_key," : ""
    group_by_clause = group_column ? "GROUP BY #{group_column}" : ""
    order_by_clause = "ORDER BY #{group_column || "1"}"

    sql = <<~SQL
      #{CURRENT_SALARIES_CTE}
      SELECT
        #{select_group}
        COUNT(*) AS headcount,
        SUM(current_salaries.amount * exchange_rates.rate_to_usd) AS total_payroll_usd,
        AVG(current_salaries.amount * exchange_rates.rate_to_usd) AS average_salary_usd,
        MIN(current_salaries.amount * exchange_rates.rate_to_usd) AS min_salary_usd,
        MAX(current_salaries.amount * exchange_rates.rate_to_usd) AS max_salary_usd
      FROM current_salaries
      INNER JOIN employees ON employees.id = current_salaries.employee_id
      INNER JOIN exchange_rates ON exchange_rates.currency = current_salaries.currency
      WHERE current_salaries.rank_within_employee = 1
        AND employees.status = 'active'
      #{group_by_clause}
      #{order_by_clause}
    SQL

    ActiveRecord::Base.connection.select_all(sql).to_a.map { |row| build_result(row, label) }
  end
  private_class_method :aggregate

  def self.build_result(row, label)
    result = {
      headcount: row["headcount"].to_i,
      total_payroll_usd: row["total_payroll_usd"].to_f.round(2),
      average_salary_usd: row["average_salary_usd"].to_f.round(2),
      min_salary_usd: row["min_salary_usd"].to_f.round(2),
      max_salary_usd: row["max_salary_usd"].to_f.round(2)
    }
    result[label] = row["group_key"] if label
    result
  end
  private_class_method :build_result
end
