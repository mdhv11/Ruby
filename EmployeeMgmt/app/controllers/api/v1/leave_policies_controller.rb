module Api
  module V1
    class LeavePoliciesController < ApplicationController

      before_action :set_department
      before_action :set_policy, only: [:show, :update, :destroy]

      def index
        policies = @department.leave_policies
        render json: policies.map { |p| policy_json(p) }, status: :ok
      end

      def show
        render json: policy_json(@policy), status: :ok
      end

      def create
        policy = @department.leave_policies.new(policy_params)

        if policy.save
          render json: policy_json(policy), status: :created
        else
          render json: { errors: policy.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @policy.update(policy_params)
          render json: policy_json(@policy), status: :ok
        else
          render json: { errors: @policy.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @policy.leaves.exists? || @policy.leave_balances.exists?
          return render json: {
            error: "Cannot delete policy with existing leave records or balances"
          }, status: :unprocessable_entity
        end

        @policy.destroy
        render json: { message: "Leave policy deleted successfully" }, status: :ok
      end

      private

      def set_department
        org = Organization.find_by(org_id: params[:organization_id])
        return render json: { error: "Organization not found" }, status: :not_found unless org

        @department = org.departments.find_by(dept_id: params[:department_id])
        render json: { error: "Department not found" }, status: :not_found unless @department
      end

      def set_policy
        @policy = @department.leave_policies.find_by(policy_id: params[:id])
        render json: { error: "Leave policy not found" }, status: :not_found unless @policy
      end

      def policy_params
        params.require(:leave_policy).permit(:leave_type, :days_allowed, :carry_forward)
      end

      def policy_json(policy)
        {
          policy_id:    policy.policy_id,
          dept_id:      policy.dept_id,
          leave_type:   policy.leave_type,
          days_allowed: policy.days_allowed,
          carry_forward: policy.carry_forward
        }
      end
    end
  end
end