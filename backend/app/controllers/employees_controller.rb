class EmployeesController < ApplicationController
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  def index
    scope = Employee
      .in_country(params[:country])
      .in_department(params[:department])
      .with_status(params[:status])
      .search(params[:q])
      .order(:last_name, :first_name)
      .includes(:salary_records)

    total_count = scope.count
    page = [params.fetch(:page, 1).to_i, 1].max
    per_page = per_page_param

    employees = scope.offset((page - 1) * per_page).limit(per_page)

    render json: {
      employees: employees.map { |employee| EmployeeSerializer.summary(employee) },
      meta: {
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    }
  end

  def show
    render json: EmployeeSerializer.detail(employee)
  end

  def create
    new_employee = Employee.new(employee_params)

    ActiveRecord::Base.transaction do
      new_employee.save!
      new_employee.salary_records.create!(initial_salary_params)
    end

    render json: EmployeeSerializer.detail(new_employee), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
  end

  def update
    if employee.update(employee_params)
      render json: EmployeeSerializer.detail(employee)
    else
      render json: { errors: employee.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def employee
    @employee ||= Employee.find(params[:id])
  end

  def per_page_param
    value = params[:per_page].to_i
    return DEFAULT_PER_PAGE if value <= 0

    value.clamp(1, MAX_PER_PAGE)
  end

  def employee_params
    params.require(:employee).permit(
      :first_name, :last_name, :email, :country, :department,
      :job_title, :status, :hire_date
    )
  end

  def initial_salary_params
    params.require(:initial_salary).permit(:amount, :currency, :effective_date, :reason)
  end
end
