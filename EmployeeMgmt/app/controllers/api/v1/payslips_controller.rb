module Api
  module V1
    class PayslipsController < ApplicationController

      before_action :set_employee
      before_action :set_payslip, only: [:show, :disburse]

      def index
        payslips = @employee.payslips.includes(:salary_structure, :payroll)
        payslips = payslips.where(year: params[:year]) if params[:year].present?
        payslips = payslips.order(year: :desc, month: :desc)

        render json: payslips.map { |p| payslip_json(p) }, status: :ok
      end

      def show
        render json: payslip_json(@payslip), status: :ok
      end

      def generate
        month = params[:month].to_i
        year  = params[:year].to_i

        unless (1..12).include?(month) && year > 2000
          return render json: { error: "Invalid month or year" }, status: :bad_request
        end

        if Payslip.exists?(emp_id: @employee.emp_id, month: month, year: year)
          return render json: { error: "Payslip already generated for #{month}/#{year}" }, status: :unprocessable_entity
        end

        current_role_history = @employee.employee_role_histories.find_by(end_date: nil)

        unless current_role_history
          return render json: { error: "Employee has no active role assigned" }, status: :unprocessable_entity
        end

        structure = SalaryStructure.find_by(role_id: current_role_history.role_id)

        unless structure
          return render json: { error: "No salary structure found for employee's current role" }, status: :unprocessable_entity
        end

        period_start = Date.new(year, month, 1)
        period_end   = Date.new(year, month, -1)

        total_overtime_hours = @employee.attendances
                                        .where(date: period_start..period_end)
                                        .sum(:overtime_hours).to_f

        dept                  = @employee.department
        overtime_rate         = dept&.overtime_pay_per_hour || 0
        overtime_bonus        = (total_overtime_hours * overtime_rate).round(2)

        unpaid_policy = LeavePolicy.find_by(dept_id: @employee.dept_id, leave_type: "unpaid")
        unpaid_days   = 0

        if unpaid_policy
          unpaid_days = Leave.where(
            emp_id:    @employee.emp_id,
            policy_id: unpaid_policy.policy_id,
            status:    "approved"
          ).where("start_date >= ? AND end_date <= ?", period_start, period_end)
                             .sum { |l| (l.end_date - l.start_date).to_i + 1 }
        end

        daily_rate            = (structure.basic_salary / 22.0).round(2)  # 22 working days assumed
        unpaid_leave_deduct   = (daily_rate * unpaid_days).round(2)

        payslip = @employee.payslips.new(
          structure_id:           structure.structure_id,
          month:                  month,
          year:                   year,
          overtime_bonus:         overtime_bonus,
          unpaid_leave_deduction: unpaid_leave_deduct,
          generated_date:         Date.today
        # net_salary calculated automatically in before_save
        )

        if payslip.save
          render json: payslip_json(payslip), status: :created
        else
          render json: { errors: payslip.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def disburse
        if @payslip.disbursed?
          return render json: { error: "Payslip has already been disbursed" }, status: :unprocessable_entity
        end

        payroll = Payroll.new(
          payslip_id:      @payslip.payslip_id,
          amount_disbursed: @payslip.net_salary,
          date:            params[:date] || Date.today
        )

        if payroll.save
          render json: {
            message: "Salary disbursed successfully",
            payslip: payslip_json(@payslip.reload)
          }, status: :ok
        else
          render json: { errors: payroll.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_employee
        @employee = Employee.find_by(emp_id: params[:employee_id])
        render json: { error: "Employee not found" }, status: :not_found unless @employee
      end

      def set_payslip
        @payslip = @employee.payslips.find_by(payslip_id: params[:id])
        render json: { error: "Payslip not found" }, status: :not_found unless @payslip
      end

      def payslip_json(payslip)
        structure = payslip.salary_structure
        {
          payslip_id:             payslip.payslip_id,
          emp_id:                 payslip.emp_id,
          month:                  payslip.month,
          year:                   payslip.year,
          generated_date:         payslip.generated_date,
          basic_salary:           structure&.basic_salary,
          bonus:                  structure&.bonus,
          tax_percent:            structure&.tax_percent,
          deductions:             structure&.deductions,
          overtime_bonus:         payslip.overtime_bonus,
          unpaid_leave_deduction: payslip.unpaid_leave_deduction,
          net_salary:             payslip.net_salary,
          disbursed:              payslip.disbursed?,
          payroll:                payroll_json(payslip.payroll)
        }
      end

      def payroll_json(payroll)
        return nil unless payroll
        {
          payroll_id:      payroll.payroll_id,
          amount_disbursed: payroll.amount_disbursed,
          date:            payroll.date
        }
      end
    end
  end
end
 