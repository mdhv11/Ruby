module Api
  module V1
    class EmployeesController < ApplicationController

      before_action :set_employee, only: [:show, :update, :deactivate, :profile, :manager_performance, :transfer, :change_role, :onboard, :leave_balances]

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

      def manager_performance
        department_team_ids = department_team_member_ids(@employee)
        project_team_ids = project_team_member_ids(@employee) - department_team_ids
        reviews = filtered_manager_reviews(@employee, (department_team_ids + project_team_ids).uniq)
        department_reviews = filtered_manager_reviews(@employee, department_team_ids)
        project_reviews = filtered_manager_reviews(@employee, project_team_ids)

        overall_team_ids = (department_team_ids + project_team_ids).uniq

        render json: {
          manager: employee_summary_json(@employee),
          team_member_count: overall_team_ids.count,
          review_count: reviews.count,
          average_rating: average_rating_for(reviews),
          reviews: reviews.order(review_date: :desc).map { |review| manager_review_json(review) },
          overall: manager_performance_summary(overall_team_ids, reviews),
          department_team: manager_performance_summary(department_team_ids, department_reviews),
          project_team: manager_performance_summary(project_team_ids, project_reviews)
        }, status: :ok
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

      def project_overload_detection
        max_projects = params[:max_projects].present? ? params[:max_projects].to_i : 3
        return render json: { error: "max_projects must be greater than 0" }, status: :bad_request if max_projects <= 0

        employees = Employee.includes(:department, employee_projects: :project).where(status: "active")
        employees = employees.where(dept_id: params[:dept_id]) if params[:dept_id].present?

        if params[:org_id].present?
          dept_ids = Department.where(org_id: params[:org_id]).pluck(:dept_id)
          employees = employees.where(dept_id: dept_ids)
        end

        overloaded_employees = employees.filter_map do |employee|
          active_projects = active_projects_for(employee)
          next unless active_projects.count > max_projects

          {
            emp_id: employee.emp_id,
            name: employee.name,
            department: dept_info(employee.department),
            active_project_count: active_projects.count,
            projects: active_projects
          }
        end

        render json: {
          max_projects: max_projects,
          count: overloaded_employees.count,
          employees: overloaded_employees
        }, status: :ok
      end

      def salary_reduction_candidates
        month = params[:month].to_i
        year  = params[:year].to_i

        unless (1..12).include?(month) && year > 2000
          return render json: { error: "month and year params are required and must be valid" }, status: :bad_request
        end

        attendance_below = params[:attendance_below].present? ? params[:attendance_below].to_f : 80.0
        employees = Employee.includes(:department, :attendances).where(status: "active")
        employees = employees.where(dept_id: params[:dept_id]) if params[:dept_id].present?

        if params[:org_id].present?
          dept_ids = Department.where(org_id: params[:org_id]).pluck(:dept_id)
          employees = employees.where(dept_id: dept_ids)
        end

        period_start = Date.new(year, month, 1)
        period_end   = Date.new(year, month, -1)

        candidates = employees.filter_map do |employee|
          reduction_candidate_json(employee, month, year, period_start, period_end, attendance_below)
        end

        render json: {
          month: month,
          year: year,
          attendance_below: attendance_below.round(2),
          count: candidates.count,
          employees: candidates
        }, status: :ok
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

      def leave_balances
        year = params[:year]&.to_i || Date.today.year

        balances = @employee.leave_balances
                            .where(year: year)
                            .includes(:leave_policy)

        render json: balances.map { |balance| leave_balance_json(balance) }, status: :ok
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
        active_projects_for(employee)
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

      def leave_balance_json(balance)
        {
          policy:        leave_policy_info(balance.leave_policy),
          year:          balance.year,
          total_allowed: balance.total_allowed,
          used:          balance.used,
          remaining:     balance.remaining
        }
      end

      def leave_policy_info(policy)
        return nil unless policy

        {
          policy_id: policy.policy_id,
          leave_type: policy.leave_type,
          days_allowed: policy.days_allowed
        }
      end

      def department_team_member_ids(manager)
        Employee.where(
          dept_id: Department.where(manager_id: manager.emp_id).select(:dept_id),
          status: "active"
        ).where.not(emp_id: manager.emp_id).pluck(:emp_id)
      end

      def project_team_member_ids(manager)
        EmployeeProject.joins(:project)
                       .where(projects: { project_manager: manager.emp_id })
                       .where.not(emp_id: manager.emp_id)
                       .pluck(:emp_id)
                       .uniq
      end

      def filtered_manager_reviews(manager, reviewer_ids)
        reviews = manager.performance_reviews.includes(:reviewer)
        reviews = reviews.where(reviewer_id: reviewer_ids)

        if params[:year].present?
          year = params[:year].to_i
          reviews = reviews.where(review_date: Date.new(year, 1, 1)..Date.new(year, 12, 31))
        end

        reviews
      end

      def manager_performance_summary(team_member_ids, reviews)
        {
          team_member_count: team_member_ids.count,
          review_count: reviews.count,
          average_rating: average_rating_for(reviews)
        }
      end

      def average_rating_for(reviews)
        reviews.average(:rating)&.round(2)&.to_f
      end

      def manager_review_json(review)
        {
          review_id: review.review_id,
          rating: review.rating,
          feedback: review.feedback,
          review_date: review.review_date,
          reviewer: {
            emp_id: review.reviewer.emp_id,
            name: review.reviewer.name
          }
        }
      end

      def active_projects_for(employee)
        employee.employee_projects
                .includes(:project)
                .filter_map do |employee_project|
          project = employee_project.project
          next if project.nil? || project.status == "completed"

          {
            project_id: project.project_id,
            project_name: project.project_name,
            project_role: employee_project.project_role,
            status: project.status
          }
        end
      end

      def reduction_candidate_json(employee, month, year, period_start, period_end, attendance_below)
        records = employee.attendances.for_month(month, year)
        present_count = records.status_present.count
        half_day_count = records.status_half_day.count

        working_days = employee.working_days_in_month(month, year)
        attendance_pct = employee.attendance_percentage_for(month, year)
        unpaid_days = unpaid_leave_days_for(employee, period_start, period_end)
        half_day_equivalent = employee.half_day_absence_equivalent_for(month, year)

        reasons = []
        reasons << "unpaid_leave" if unpaid_days.positive?
        reasons << "low_attendance" if attendance_pct < attendance_below
        return nil if reasons.empty?
        reasons << "half_day_adjustment" if half_day_equivalent.positive?

        {
          emp_id: employee.emp_id,
          name: employee.name,
          department: dept_info(employee.department),
          month: month,
          year: year,
          unpaid_leave_days: unpaid_days,
          half_day_absence_equivalent: half_day_equivalent,
          attendance_percentage: attendance_pct,
          working_days_in_month: working_days,
          reasons: reasons
        }
      end

      def unpaid_leave_days_for(employee, period_start, period_end)
        unpaid_policy = LeavePolicy.find_by(dept_id: employee.dept_id, leave_type: "unpaid")
        return 0 unless unpaid_policy

        Leave.where(
          emp_id: employee.emp_id,
          policy_id: unpaid_policy.policy_id,
          status: "approved"
        ).where("start_date <= ? AND end_date >= ?", period_end, period_start)
         .sum { |leave| overlapping_days_with_period(leave, period_start, period_end) }
      end

      def overlapping_days_with_period(leave, period_start, period_end)
        overlap_start = [leave.start_date, period_start].max
        overlap_end = [leave.end_date, period_end].min
        return 0 if overlap_start > overlap_end

        (overlap_end - overlap_start).to_i + 1
      end
    end
  end
end
 
