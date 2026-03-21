module Api
  module V1
    class AttendancesController < ApplicationController

      before_action :set_employee
      before_action :set_attendance, only: [:show, :update]

      def index
        unless params[:month].present? && params[:year].present?
          return render json: { error: "month and year params are required" }, status: :bad_request
        end

        month = params[:month].to_i
        year  = params[:year].to_i

        unless (1..12).include?(month)
          return render json: { error: "month must be between 1 and 12" }, status: :bad_request
        end

        attendances = @employee.attendances.for_month(month, year).order(:date)

        render json: {
          employee: employee_info,
          month:    month,
          year:     year,
          records:  attendances.map { |a| attendance_json(a) }
        }, status: :ok
      end

      def show
        render json: attendance_json(@attendance), status: :ok
      end

      def summary
        unless params[:month].present? && params[:year].present?
          return render json: { error: "month and year params are required" }, status: :bad_request
        end

        month = params[:month].to_i
        year  = params[:year].to_i

        records = @employee.attendances.for_month(month, year)

        present_count  = records.status_present.count
        half_day_count = records.status_half_day.count
        absent_count   = records.status_absent.count
        total_overtime = records.sum(:overtime_hours).to_f.round(2)
        total_hours    = records.sum(:total_hours).to_f.round(2)

        dept = @employee.department
        working_days_in_month = count_working_days(month, year, dept&.working_days || [])

        render json: {
          employee:               employee_info,
          month:                  month,
          year:                   year,
          working_days_in_month:  working_days_in_month,
          present_days:           present_count,
          half_days:              half_day_count,
          absent_days:            absent_count,
          standard_hours_applied: dept&.standard_hours || 8.0,
          total_hours_worked:     total_hours,
          total_overtime_hours:   total_overtime,
          attendance_percentage:  attendance_percentage(present_count, half_day_count, working_days_in_month)
        }, status: :ok
      end

      def create
        attendance = @employee.attendances.new(attendance_params)

        if attendance.save
          render json: attendance_json(attendance), status: :created
        else
          render json: { errors: attendance.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def bulk_create
        records_params = params[:records]

        unless records_params.is_a?(Array) && records_params.any?
          return render json: { error: "records must be a non-empty array" }, status: :bad_request
        end

        succeeded = []
        failed    = []

        records_params.each do |record|
          attendance = @employee.attendances.new(
            date:           record[:date],
            check_in_time:  record[:check_in_time],
            check_out_time: record[:check_out_time]
          )

          if attendance.save
            succeeded << attendance_json(attendance)
          else
            failed << { date: record[:date], errors: attendance.errors.full_messages }
          end
        end

        render json: {
          message:   "Bulk create complete",
          succeeded: succeeded,
          failed:    failed
        }, status: :ok
      end

      def update
        if @attendance.update(attendance_params)
          render json: attendance_json(@attendance), status: :ok
        else
          render json: { errors: @attendance.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_employee
        @employee = Employee.find_by(emp_id: params[:employee_id])
        render json: { error: "Employee not found" }, status: :not_found unless @employee
      end

      def set_attendance
        @attendance = @employee.attendances.find_by(attendance_id: params[:id])
        render json: { error: "Attendance record not found" }, status: :not_found unless @attendance
      end

      def attendance_params
        params.require(:attendance).permit(:date, :check_in_time, :check_out_time)
      end

      def count_working_days(month, year, working_days)
        return 0 if working_days.blank?

        (Date.new(year, month, 1)..Date.new(year, month, -1)).count do |d|
          working_days.include?(d.strftime("%A"))
        end
      end

      def attendance_percentage(present, half_days, working_days)
        return 0.0 if working_days.zero?

        effective_days = present + (half_days * 0.5)
        ((effective_days / working_days.to_f) * 100).round(2)
      end

      def employee_info
        { emp_id: @employee.emp_id, name: @employee.name, department: @employee.department&.name }
      end

      def attendance_json(attendance)
        {
          attendance_id:  attendance.attendance_id,
          date:           attendance.date,
          check_in_time:  attendance.check_in_time,
          check_out_time: attendance.check_out_time,
          total_hours:    attendance.total_hours,
          overtime_hours: attendance.overtime_hours,
          status:         attendance.status
        }
      end
    end
  end
end