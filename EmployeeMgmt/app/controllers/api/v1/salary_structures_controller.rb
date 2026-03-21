module Api
  module V1
    class SalaryStructuresController < ApplicationController

      before_action :set_organization
      before_action :set_department
      before_action :set_role
      before_action :set_structure, only: [:show, :update, :destroy]

      def show
        render json: structure_json(@structure), status: :ok
      end

      def create
        if SalaryStructure.exists?(role_id: @role.role_id)
          return render json: { error: "A salary structure already exists for this role. Use PATCH to update it." }, status: :unprocessable_entity
        end

        structure = SalaryStructure.new(structure_params.merge(role_id: @role.role_id))

        if structure.save
          render json: structure_json(structure), status: :created
        else
          render json: { errors: structure.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @structure.update(structure_params)
          render json: structure_json(@structure), status: :ok
        else
          render json: { errors: @structure.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @structure.payslips.exists?
          return render json: {
            error: "Cannot delete structure with existing payslips. Archive the role instead."
          }, status: :unprocessable_entity
        end

        @structure.destroy
        render json: { message: "Salary structure deleted successfully" }, status: :ok
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
        @role = @department.roles.find_by(role_id: params[:role_id], org_id: @organization.org_id)
        render json: { error: "Role not found" }, status: :not_found unless @role
      end

      def set_structure
        @structure = SalaryStructure.find_by(role_id: @role.role_id)
        render json: { error: "Salary structure not found for this role" }, status: :not_found unless @structure
      end

      def structure_params
        params.require(:salary_structure).permit(:basic_salary, :bonus, :tax_percent, :deductions)
      end

      def structure_json(structure)
        {
          structure_id: structure.structure_id,
          role_id:      structure.role_id,
          role_name:    structure.role.name,
          basic_salary: structure.basic_salary,
          bonus:        structure.bonus,
          tax_percent:  structure.tax_percent,
          deductions:   structure.deductions
        }
      end
    end
  end
end
