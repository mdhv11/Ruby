module Api
  module V1
    class ProjectsController < ApplicationController

      before_action :set_department
      before_action :set_project, only: [:show, :update, :assign_manager, :add_members, :remove_member, :update_status, :members]

      def index
        projects = @department.projects.includes(:manager)
        projects = projects.where(status: params[:status]) if params[:status].present?

        render json: projects.map { |p| project_json(p) }, status: :ok
      end

      def show
        render json: project_json(@project), status: :ok
      end

      def members
        members = @project.employee_projects.includes(:employee)

        render json: members.map { |ep| member_json(ep) }, status: :ok
      end

      def create
        project = @department.projects.new(project_params.merge(status: "assigned"))

        if project.save
          render json: project_json(project), status: :created
        else
          render json: { errors: project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @project.update(project_params)
          render json: project_json(@project), status: :ok
        else
          render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def assign_manager
        emp_id = params[:emp_id]

        return render json: { error: "emp_id is required" }, status: :bad_request unless emp_id.present?

        unless Employee.exists?(emp_id: emp_id, dept_id: @department.dept_id)
          return render json: { error: "Employee not found in this department" }, status: :not_found
        end

        if @project.update(project_manager: emp_id)
          render json: {
            message: "Project manager assigned successfully",
            manager: manager_info(@project.reload.manager)
          }, status: :ok
        else
          render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update_status
        new_status = params[:status]

        unless Project.statuses.key?(new_status)
          return render json: { error: "Invalid status. Must be: #{Project.statuses.keys.join(', ')}" }, status: :bad_request
        end

        if @project.status_completed?
          return render json: { error: "Cannot change status of a completed project" }, status: :unprocessable_entity
        end

        attrs = { status: new_status }
        # Auto-set end_date when completing if not already set
        attrs[:end_date] = Date.today if new_status == "completed" && @project.end_date.nil?

        if @project.update(attrs)
          render json: project_json(@project), status: :ok
        else
          render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def add_members
        members_params = params[:members]

        unless members_params.is_a?(Array) && members_params.any?
          return render json: { error: "members must be a non-empty array" }, status: :bad_request
        end

        if @project.status_completed?
          return render json: { error: "Cannot add members to a completed project" }, status: :unprocessable_entity
        end

        dept_emp_ids = Employee.where(dept_id: @department.dept_id, status: "active").pluck(:emp_id)

        succeeded = []
        failed    = []

        members_params.each do |m|
          emp_id       = m[:emp_id]
          project_role = m[:project_role]

          unless dept_emp_ids.include?(emp_id)
            failed << { emp_id: emp_id, error: "Employee not found or not active in this department" }
            next
          end

          if EmployeeProject.exists?(emp_id: emp_id, project_id: @project.project_id)
            failed << { emp_id: emp_id, error: "Already a member of this project" }
            next
          end

          ep = EmployeeProject.new(
            emp_id:        emp_id,
            project_id:    @project.project_id,
            project_role:  project_role,
            assigned_date: Date.today
          )

          if ep.save
            succeeded << { emp_id: emp_id, project_role: project_role }
          else
            failed << { emp_id: emp_id, error: ep.errors.full_messages }
          end
        end

        render json: {
          message:   "Add members complete",
          succeeded: succeeded,
          failed:    failed
        }, status: :ok
      end

      def remove_member
        emp_id = params[:emp_id]

        return render json: { error: "emp_id is required" }, status: :bad_request unless emp_id.present?

        if @project.project_manager == emp_id
          return render json: { error: "Cannot remove the project manager. Reassign the manager first." }, status: :unprocessable_entity
        end

        ep = EmployeeProject.find_by(emp_id: emp_id, project_id: @project.project_id)

        unless ep
          return render json: { error: "Employee is not a member of this project" }, status: :not_found
        end

        ep.destroy
        render json: { message: "Member removed successfully" }, status: :ok
      end

      private

      def set_department
        @department = Department.find_by(dept_id: params[:department_id])
        render json: { error: "Department not found" }, status: :not_found unless @department
      end

      def set_project
        @project = @department.projects.find_by(project_id: params[:id])
        render json: { error: "Project not found" }, status: :not_found unless @project
      end

      def project_params
        params.require(:project).permit(:project_name, :start_date, :end_date)
      end

      def project_json(project)
        {
          project_id:      project.project_id,
          project_name:    project.project_name,
          dept_id:         project.dept_id,
          status:          project.status,
          start_date:      project.start_date,
          end_date:        project.end_date,
          manager:         manager_info(project.manager),
          member_count:    project.employee_projects.size
        }
      end

      def manager_info(manager)
        return nil unless manager
        { emp_id: manager.emp_id, name: manager.name }
      end

      def member_json(ep)
        {
          emp_id:        ep.employee.emp_id,
          name:          ep.employee.name,
          project_role:  ep.project_role,
          assigned_date: ep.assigned_date
        }
      end
    end
  end
end
 