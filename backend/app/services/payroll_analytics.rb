# Answers the "how does the org pay people" questions the HR Manager needs:
# headcount, total payroll cost, and salary distribution (average, median,
# min, max), broken down by country or department, in a single common
# currency (USD).
#
# Implemented as SQL rather than loading records into Ruby: "current salary
# per employee" (a window function over salary_records, since salary history
# means an employee can have many rows) joined to exchange_rates for
# conversion, aggregated in the database. This scales to 10,000+ employees
# without pulling every salary record into memory just to find each
# employee's latest one.
#
# `group_column` is always one of two hardcoded, non-user-supplied SQL
# fragments (never request input), so string interpolation here does not
# introduce a SQL injection risk.
class PayrollAnalytics
  CURRENT_USD_SALARIES_CTE = <<~SQL.squish
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
    ),
    current_usd_salaries AS (
      SELECT
        employees.country,
        employees.department,
        current_salaries.amount * exchange_rates.rate_to_usd AS amount_usd
      FROM current_salaries
      INNER JOIN employees ON employees.id = current_salaries.employee_id
      INNER JOIN exchange_rates ON exchange_rates.currency = current_salaries.currency
      WHERE current_salaries.rank_within_employee = 1
        AND employees.status = 'active'
    )
  SQL

  def self.by_country
    aggregate(group_column: "country", label: :country)
  end

  def self.by_department
    aggregate(group_column: "department", label: :department)
  end

  def self.overall
    aggregate(group_column: nil, label: nil).first
  end

  def self.aggregate(group_column:, label:)
    stats_by_key = summary_stats(group_column)
    medians_by_key = medians(group_column)

    stats_by_key.map do |row|
      build_result(row, medians_by_key[row["group_key"]], label)
    end
  end
  private_class_method :aggregate

  def self.summary_stats(group_column)
    select_group = group_column ? "#{group_column} AS group_key," : ""
    group_by_clause = group_column ? "GROUP BY #{group_column}" : ""
    order_by_clause = "ORDER BY #{group_column || "1"}"

    sql = <<~SQL
      #{CURRENT_USD_SALARIES_CTE}
      SELECT
        #{select_group}
        COUNT(*) AS headcount,
        SUM(amount_usd) AS total_payroll_usd,
        AVG(amount_usd) AS average_salary_usd,
        MIN(amount_usd) AS min_salary_usd,
        MAX(amount_usd) AS max_salary_usd
      FROM current_usd_salaries
      #{group_by_clause}
      #{order_by_clause}
    SQL

    ActiveRecord::Base.connection.select_all(sql).to_a
  end
  private_class_method :summary_stats

  # The standard portable "median via ROW_NUMBER" pattern: for each group,
  # rank rows by amount and take the middle one (or average the two middle
  # ones for an even count). Integer division makes `(cnt+1)/2` and
  # `(cnt+2)/2` land on the same row when `cnt` is odd, and on the two
  # middle rows when `cnt` is even — no vendor-specific function (e.g.
  # Postgres's PERCENTILE_CONT) needed, so this works unchanged on both
  # SQLite (dev/test) and Postgres (production).
  def self.medians(group_column)
    partition_clause = group_column ? "PARTITION BY #{group_column}" : ""
    inner_select_group = group_column ? "#{group_column} AS group_key," : "NULL AS group_key,"
    group_by_clause = group_column ? "GROUP BY group_key" : ""

    sql = <<~SQL
      #{CURRENT_USD_SALARIES_CTE},
      ranked AS (
        SELECT
          #{inner_select_group}
          amount_usd,
          ROW_NUMBER() OVER (#{partition_clause} ORDER BY amount_usd) AS rn,
          COUNT(*) OVER (#{partition_clause}) AS cnt
        FROM current_usd_salaries
      )
      SELECT
        group_key,
        AVG(amount_usd) AS median_salary_usd
      FROM ranked
      WHERE rn IN ((cnt + 1) / 2, (cnt + 2) / 2)
      #{group_by_clause}
    SQL

    ActiveRecord::Base.connection.select_all(sql).to_a.index_by { |row| row["group_key"] }
  end
  private_class_method :medians

  def self.build_result(row, median_row, label)
    result = {
      headcount: row["headcount"].to_i,
      total_payroll_usd: row["total_payroll_usd"].to_f.round(2),
      average_salary_usd: row["average_salary_usd"].to_f.round(2),
      median_salary_usd: median_row["median_salary_usd"].to_f.round(2),
      min_salary_usd: row["min_salary_usd"].to_f.round(2),
      max_salary_usd: row["max_salary_usd"].to_f.round(2)
    }
    result[label] = row["group_key"] if label
    result
  end
  private_class_method :build_result
end
