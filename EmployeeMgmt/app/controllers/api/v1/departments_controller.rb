module Api
  module V1
    class DepartmentsController < ApplicationController
      UUID_FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

      before_action :set_organization
      before_action :set_department, only: [:show, :update, :destroy, :summary, :assign_manager, :monthly_salary_expense]

      def index
        departments = @organization.departments.includes(:manager)
        render json: departments_json(departments), status: :ok
      end

      def show
        render json: department_json(@department), status: :ok
      end

      def summary
        render json: {
          dept_id:         @department.dept_id,
          name:            @department.name,
          manager:         manager_info(@department),
          employee_count:  @department.employees.count,
          role_count:      @department.roles.count,
          project_count:   @department.projects.count,
          active_employees: @department.employees.where(status: "active").count
        }, status: :ok
      end

      def monthly_salary_expense
        month = params[:month].to_i
        year  = params[:year].to_i

        unless (1..12).include?(month) && year > 2000
          return render json: { error: "month and year params are required and must be valid" }, status: :bad_request
        end

        period_end = Date.new(year, month, -1)
        employee_ids = EmployeeDepartmentHistory
                         .where(dept_id: @department.dept_id)
                         .where("start_date <= ? AND (end_date IS NULL OR end_date >= ?)", period_end, period_end)
                         .pluck(:emp_id)

        payslips = Payslip.includes(:employee, :salary_structure, :payroll)
                          .where(emp_id: employee_ids, month: month, year: year)
                          .order(:emp_id)

        render json: {
          department: {
            dept_id: @department.dept_id,
            name: @department.name
          },
          month: month,
          year: year,
          employee_count: employee_ids.uniq.count,
          payslip_count: payslips.count,
          total_net_salary: payslips.sum { |payslip| payslip.net_salary.to_d }.to_f.round(2),
          total_overtime_bonus: payslips.sum { |payslip| payslip.overtime_bonus.to_d }.to_f.round(2),
          total_unpaid_leave_deduction: payslips.sum { |payslip| payslip.unpaid_leave_deduction.to_d }.to_f.round(2),
          total_disbursed: payslips.sum { |payslip| payslip.payroll&.amount_disbursed.to_d }.to_f.round(2),
          payslips: payslips.map { |payslip| monthly_salary_expense_json(payslip) }
        }, status: :ok
      end

      def create
        department = @organization.departments.new(department_params)

        if department.save
          render json: department_json(department), status: :created
        else
          render json: { errors: department.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if department_params[:manager_id].present? && !valid_uuid?(department_params[:manager_id])
          return render json: { error: "manager_id must be a valid UUID" }, status: :bad_request
        end

        if department_params[:manager_id].present?
          manager = Employee.find_by(emp_id: department_params[:manager_id])
          return render json: { error: "Manager not found" }, status: :not_found unless manager
          return render json: { error: "Manager must be an active employee" }, status: :unprocessable_entity unless manager.status_active?
          return render json: { error: "Manager must belong to this organization" }, status: :unprocessable_entity unless employee_belongs_to_organization?(manager)
        end

        update_attributes = department_params
        @department.update!(update_attributes)

        render json: department_json(@department.reload), status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def assign_manager
        emp_id = params[:emp_id]

        unless emp_id.present?
          return render json: { error: "emp_id is required" }, status: :bad_request
        end

        unless valid_uuid?(emp_id)
          return render json: { error: "emp_id must be a valid UUID" }, status: :bad_request
        end

        employee = Employee.find_by(emp_id: emp_id)
        return render json: { error: "Manager not found" }, status: :not_found unless employee
        return render json: { error: "Manager must be an active employee" }, status: :unprocessable_entity unless employee.status_active?
        return render json: { error: "Manager must belong to this organization" }, status: :unprocessable_entity unless employee_belongs_to_organization?(employee)

        @department.update!(manager_id: emp_id)

        render json: {
          message:  "Manager assigned successfully",
          manager:  manager_info(@department.reload)
        }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def destroy
        if @department.destroy
          render json: { message: "Department deleted successfully" }, status: :ok
        else
          render json: { errors: @department.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_organization
        @organization = Organization.find_by(org_id: params[:organization_id])
        render json: { error: "Organization not found" }, status: :not_found unless @organization
      end

      def set_department
        @department = @organization.departments.find_by(dept_id: params[:id])
        render json: { error: "Department not found" }, status: :not_found unless @department
      end

      def department_params
        params.require(:department).permit(:name, :manager_id, :overtime_pay_per_hour, :standard_hours, working_days: [])
      end

      def departments_json(departments)
        departments.map { |d| department_json(d) }
      end

      def department_json(department)
        {
          dept_id:               department.dept_id,
          org_id:                department.org_id,
          name:                  department.name,
          manager:               manager_info(department),
          working_days:          department.working_days,
          overtime_pay_per_hour: department.overtime_pay_per_hour
        }
      end

      def manager_info(department)
        return nil unless department.manager
        {
          emp_id: department.manager.emp_id,
          name:   department.manager.name
        }
      end

      def monthly_salary_expense_json(payslip)
        {
          payslip_id: payslip.payslip_id,
          emp_id: payslip.emp_id,
          employee_name: payslip.employee&.name,
          net_salary: payslip.net_salary,
          overtime_bonus: payslip.overtime_bonus,
          unpaid_leave_deduction: payslip.unpaid_leave_deduction,
          disbursed: payslip.disbursed?,
          amount_disbursed: payslip.payroll&.amount_disbursed
        }
      end

      def employee_belongs_to_organization?(employee)
        employee.department&.org_id == @organization.org_id
      end

      def valid_uuid?(value)
        value.to_s.match?(UUID_FORMAT)
      end
    end
  end
end
