module Api
  module V1
    class RolesController < ApplicationController

      before_action :set_organization
      before_action :set_department
      before_action :set_role, only: [:show, :update, :destroy]

      def index
        roles = @department.roles.includes(:salary_structure)
        render json: roles.map { |r| role_json(r) }, status: :ok
      end

      def show
        render json: role_json(@role, detailed: true), status: :ok
      end

      def create
        role = @department.roles.new(role_params.merge(org_id: @organization.org_id))

        if role.save
          render json: role_json(role), status: :created
        else
          render json: { errors: role.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @role.update(role_params)
          render json: role_json(@role), status: :ok
        else
          render json: { errors: @role.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @role.current_employees.exists?
          return render json: {
            error: "Cannot delete role with active employees. Reassign them first."
          }, status: :unprocessable_entity
        end

        if @role.destroy
          render json: { message: "Role deleted successfully" }, status: :ok
        else
          render json: { errors: @role.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_organization
        @organization = Organization.find_by(org_id: params[:organization_id])
        render json: { error: "Organization not found" }, status: :not_found unless @organization
      end

      def set_department
        @department = @organization.departments.find_by(dept_id: params[:department_id])
        render json: { error: "Department not found" }, status: :not_found unless @department
      end

      def set_role
        @role = @department.roles.find_by(role_id: params[:id])
        render json: { error: "Role not found" }, status: :not_found unless @role
      end

      def role_params
        params.require(:role).permit(:name, :description)
      end

      def role_json(role, detailed: false)
        data = {
          role_id:     role.role_id,
          org_id:      role.org_id,
          dept_id:     role.dept_id,
          name:        role.name,
          description: role.description,
          has_salary_structure: role.salary_structure.present?
        }

        if detailed
          data[:salary_structure]   = structure_brief(role.salary_structure)
          data[:current_headcount]  = role.current_employees.count
        end

        data
      end

      def structure_brief(structure)
        return nil unless structure
        {
          structure_id: structure.structure_id,
          basic_salary: structure.basic_salary,
          net_salary_approx: approximate_net(structure)
        }
      end

      def approximate_net(structure)
        return nil unless structure
        gross = (structure.basic_salary + (structure.bonus || 0))
        tax   = (gross * ((structure.tax_percent || 0) / 100.0))
        (gross - tax - (structure.deductions || 0)).round(2)
      end
    end
  end
end
 