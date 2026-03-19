module Api
  module V1
    class DepartmentsController < ApplicationController

      before_action :set_organization
      before_action :set_department, only: [:show, :update, :destroy, :summary, :assign_manager]

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

      def create
        department = @organization.departments.new(department_params)

        if department.save
          render json: department_json(department), status: :created
        else
          render json: { errors: department.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @department.update(department_params)
          render json: department_json(@department), status: :ok
        else
          render json: { errors: @department.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def assign_manager
        emp_id = params[:emp_id]

        unless emp_id.present?
          return render json: { error: "emp_id is required" }, status: :bad_request
        end

        unless Employee.exists?(emp_id: emp_id, dept_id: @department.dept_id)
          return render json: { error: "Employee not found in this department" }, status: :unprocessable_entity
        end

        if @department.update(manager_id: emp_id)
          render json: {
            message:  "Manager assigned successfully",
            manager:  manager_info(@department.reload)
          }, status: :ok
        else
          render json: { errors: @department.errors.full_messages }, status: :unprocessable_entity
        end
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
        params.require(:department).permit(:name, :overtime_pay_per_hour, :standard_hours, working_days: [])
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
    end
  end
end