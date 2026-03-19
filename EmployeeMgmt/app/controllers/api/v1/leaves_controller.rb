module Api
  module V1
    class LeavesController < ApplicationController

      before_action :set_employee
      before_action :set_leave, only: [:show, :approve, :reject, :cancel]

      def index
        leaves = @employee.leaves.includes(:leave_policy, :approver)

        leaves = leaves.where(status: params[:status]) if params[:status].present?

        if params[:year].present?
          year = params[:year].to_i
          leaves = leaves.where(start_date: Date.new(year, 1, 1)..Date.new(year, 12, 31))
        end

        render json: leaves.map { |l| leave_json(l) }, status: :ok
      end

      def show
        render json: leave_json(@leave), status: :ok
      end

      def balances
        year = params[:year]&.to_i || Date.today.year

        balances = LeaveBalance.where(emp_id: @employee.emp_id, year: year)
                               .includes(:leave_policy)

        render json: balances.map { |b| balance_json(b) }, status: :ok
      end

      def create
        leave = @employee.leaves.new(leave_params.merge(status: "pending"))

        if leave.save
          render json: leave_json(leave), status: :created
        else
          render json: { errors: leave.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def approve
        unless @leave.status_pending?
          return render json: { error: "Only pending leaves can be approved" }, status: :unprocessable_entity
        end

        approver_id = params[:approver_id]
        return render json: { error: "approver_id is required" }, status: :bad_request unless approver_id.present?
        return render json: { error: "Approver not found" }, status: :not_found unless Employee.exists?(emp_id: approver_id)

        if @leave.update(status: "approved", approved_by: approver_id)
          render json: {
            message: "Leave approved",
            leave:   leave_json(@leave.reload)
          }, status: :ok
        else
          render json: { errors: @leave.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def reject
        unless @leave.status_pending?
          return render json: { error: "Only pending leaves can be rejected" }, status: :unprocessable_entity
        end

        approver_id = params[:approver_id]
        return render json: { error: "approver_id is required" }, status: :bad_request unless approver_id.present?
        return render json: { error: "Approver not found" }, status: :not_found unless Employee.exists?(emp_id: approver_id)

        if @leave.update(status: "rejected", approved_by: approver_id)
          render json: {
            message: "Leave rejected",
            leave:   leave_json(@leave.reload)
          }, status: :ok
        else
          render json: { errors: @leave.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def cancel
        unless @leave.status_pending?
          return render json: { error: "Only pending leaves can be cancelled" }, status: :unprocessable_entity
        end

        @leave.update!(status: "rejected")
        render json: { message: "Leave cancelled successfully" }, status: :ok
      end

      private

      def set_employee
        @employee = Employee.find_by(emp_id: params[:employee_id])
        render json: { error: "Employee not found" }, status: :not_found unless @employee
      end

      def set_leave
        @leave = @employee.leaves.find_by(leave_id: params[:id])
        render json: { error: "Leave not found" }, status: :not_found unless @leave
      end

      def leave_params
        params.require(:leave).permit(:policy_id, :start_date, :end_date, :reason)
      end

      def leave_json(leave)
        {
          leave_id:      leave.leave_id,
          emp_id:        leave.emp_id,
          policy:        policy_brief(leave.leave_policy),
          start_date:    leave.start_date,
          end_date:      leave.end_date,
          duration_days: leave.duration_days,
          reason:        leave.reason,
          status:        leave.status,
          approved_by:   approver_brief(leave.approver)
        }
      end

      def balance_json(balance)
        {
          policy:        policy_brief(balance.leave_policy),
          year:          balance.year,
          total_allowed: balance.total_allowed,
          used:          balance.used,
          remaining:     balance.remaining
        }
      end

      def policy_brief(policy)
        return nil unless policy
        { policy_id: policy.policy_id, leave_type: policy.leave_type, days_allowed: policy.days_allowed }
      end

      def approver_brief(approver)
        return nil unless approver
        { emp_id: approver.emp_id, name: approver.name }
      end
    end
  end
end
 