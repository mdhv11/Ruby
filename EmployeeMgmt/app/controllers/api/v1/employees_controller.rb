module Api
  module V1
    class EmployeesController < ApplicationController

      before_action :set_employee, only: [:show, :update, :deactivate, :profile, :transfer, :change_role, :onboard]

      def index
        employees = Employee.includes(:department, :employee_role_histories)

        employees = employees.where(dept_id: params[:dept_id]) if params[:dept_id].present?
        employees = employees.where(status: params[:status])   if params[:status].present?

        if params[:org_id].present?
          dept_ids = Department.where(org_id: params[:org_id]).pluck(:dept_id)
          employees = employees.where(dept_id: dept_ids)
        end

        render json: employees.map { |e| employee_summary_json(e) }, status: :ok
      end

      def show
        render json: employee_summary_json(@employee), status: :ok
      end

      def profile
        render json: {
          **employee_summary_json(@employee),
          current_role:       role_info(@employee.current_role),
          department:         dept_info(@employee.department),
          department_history: department_history_json(@employee),
          role_history:       role_history_json(@employee),
          active_projects:    active_projects_json(@employee),
          latest_review:      latest_review_json(@employee)
        }, status: :ok
      end

      def register
        employee = Employee.new(register_params.merge(status: "onboarding"))

        if employee.save
          render json: employee_summary_json(employee), status: :created
        else
          render json: { errors: employee.errors.full_messages }, status: :unprocessable_entity
        end
      end


      def onboard
        unless @employee.status_onboarding?
          return render json: { error: "Employee is not in onboarding status" }, status: :unprocessable_entity
        end

        dept_id = params[:dept_id]
        role_id = params[:role_id]
        join_date = params[:joining_date]&.to_date || Date.current.to_date

        return render json: { error: "dept_id is required" }, status: :bad_request unless dept_id.present?

        department = Department.find_by(dept_id: dept_id)
        return render json: { error: "Department not found" }, status: :not_found unless department

        role = nil
        if role_id.present?
          role = Role.find_by(role_id: role_id)
          return render json: { error: "Role not found" }, status: :not_found unless role
          return render json: { error: "Role does not belong to the selected department" }, status: :unprocessable_entity unless role.dept_id == department.dept_id
        end

        ActiveRecord::Base.transaction do
          @employee.update!(
            dept_id:      department.dept_id,
            joining_date: join_date,
            status:       "active"
          )

          EmployeeDepartmentHistory.create!(
            emp_id:     @employee.emp_id,
            dept_id:    department.dept_id,
            start_date: join_date,
            end_date:   nil
          )

          if role.present?
            EmployeeRoleHistory.create!(
              emp_id:     @employee.emp_id,
              role_id:    role.role_id,
              start_date: join_date,
              end_date:   nil
            )
          end
        end

        render json: employee_summary_json(@employee.reload), status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def update
        if @employee.update(employee_params)
          render json: employee_summary_json(@employee), status: :ok
        else
          render json: { errors: @employee.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def deactivate
        new_status = params[:status]

        unless %w[resigned terminated].include?(new_status)
          return render json: { error: "status must be 'resigned' or 'terminated'" }, status: :bad_request
        end

        if @employee.status_terminated? || @employee.status_resigned?
          return render json: { error: "Employee is already inactive" }, status: :unprocessable_entity
        end

        attrs = { status: new_status }
        attrs[:termination_reason] = params[:termination_reason] if new_status == "terminated"
        attrs[:resignation_date]   = params[:resignation_date]   if new_status == "resigned"

        ActiveRecord::Base.transaction do
          @employee.update!(attrs)

          close_date = (params[:resignation_date] || Date.today).to_date

          @employee.employee_department_histories.where(end_date: nil).update_all(end_date: close_date)
          @employee.employee_role_histories.where(end_date: nil).update_all(end_date: close_date)
        end

        render json: { message: "Employee deactivated", employee: employee_summary_json(@employee.reload) }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def transfer
        new_dept_id      = params[:dept_id]
        effective_date   = params[:effective_date]&.to_date || Date.today

        return render json: { error: "dept_id is required" }, status: :bad_request unless new_dept_id.present?
        return render json: { error: "Employee is not active" }, status: :unprocessable_entity unless @employee.status_active?

        new_dept = Department.find_by(dept_id: new_dept_id)
        return render json: { error: "Department not found" }, status: :not_found unless new_dept

        if new_dept_id == @employee.dept_id
          return render json: { error: "Employee is already in this department" }, status: :unprocessable_entity
        end

        ActiveRecord::Base.transaction do
          @employee.employee_department_histories.where(end_date: nil).update_all(end_date: effective_date)
          @employee.employee_role_histories.where(end_date: nil).update_all(end_date: effective_date)

          EmployeeDepartmentHistory.create!(
            emp_id:     @employee.emp_id,
            dept_id:    new_dept_id,
            start_date: effective_date,
            end_date:   nil
          )

          @employee.update!(dept_id: new_dept_id)
        end

        render json: {
          message:    "Employee transferred successfully",
          employee:   employee_summary_json(@employee.reload),
          new_department: dept_info(new_dept)
        }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def change_role
        new_role_id    = params[:role_id]
        effective_date = params[:effective_date]&.to_date || Date.today

        return render json: { error: "role_id is required" }, status: :bad_request unless new_role_id.present?
        return render json: { error: "Employee is not active" }, status: :unprocessable_entity unless @employee.status_active?

        new_role = Role.find_by(role_id: new_role_id)
        return render json: { error: "Role not found" }, status: :not_found unless new_role
        return render json: { error: "Role does not belong to the employee's department" }, status: :unprocessable_entity unless new_role.dept_id == @employee.dept_id

        current_open = @employee.employee_role_histories.find_by(end_date: nil)

        if current_open&.role_id == new_role_id
          return render json: { error: "Employee already has this role" }, status: :unprocessable_entity
        end

        ActiveRecord::Base.transaction do
          current_open&.update!(end_date: effective_date)

          EmployeeRoleHistory.create!(
            emp_id:     @employee.emp_id,
            role_id:    new_role_id,
            start_date: effective_date,
            end_date:   nil
          )
        end

        render json: {
          message:  "Role updated successfully",
          new_role: role_info(new_role)
        }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def set_employee
        @employee = Employee.find_by(emp_id: params[:id])
        render json: { error: "Employee not found" }, status: :not_found unless @employee
      end

      def employee_params
        params.require(:employee).permit(
          :name, :email, :phone, :address, :gender,
          :dept_id, :joining_date, :date_of_birth,
          :termination_reason, :resignation_date
        )
      end

      def register_params
        params.require(:employee).permit(
          :name, :email, :phone, :address,
          :gender, :date_of_birth
        )
      end

      def employee_summary_json(employee)
        {
          emp_id:       employee.emp_id,
          name:         employee.name,
          email:        employee.email,
          phone:        employee.phone,
          gender:       employee.gender,
          dept_id:      employee.dept_id,
          joining_date: employee.joining_date,
          status:       employee.status
        }
      end

      def dept_info(dept)
        return nil unless dept
        { dept_id: dept.dept_id, name: dept.name }
      end

      def role_info(role)
        return nil unless role
        { role_id: role.role_id, name: role.name }
      end

      def department_history_json(employee)
        employee.employee_department_histories
                .includes(:department)
                .order(:start_date)
                .map do |h|
          {
            department: dept_info(h.department),
            start_date: h.start_date,
            end_date:   h.end_date
          }
        end
      end

      def role_history_json(employee)
        employee.employee_role_histories
                .includes(:role)
                .order(:start_date)
                .map do |h|
          {
            role:       role_info(h.role),
            start_date: h.start_date,
            end_date:   h.end_date
          }
        end
      end

      def active_projects_json(employee)
        employee.employee_projects
                .includes(:project)
                .select { |ep| ep.project&.status != "completed" }
                .map do |ep|
          {
            project_id:   ep.project.project_id,
            project_name: ep.project.project_name,
            project_role: ep.project_role,
            status:       ep.project.status
          }
        end
      end

      def latest_review_json(employee)
        review = employee.performance_reviews.order(review_date: :desc).first
        return nil unless review
        {
          review_date: review.review_date,
          rating:      review.rating,
          feedback:    review.feedback
        }
      end
    end
  end
end
 
