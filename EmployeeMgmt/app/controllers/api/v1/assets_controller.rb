module Api
  module V1
    class AssetsController < ApplicationController

      before_action :set_asset, only: [:show, :update, :destroy, :assign, :return_asset, :history]

      def index
        assets = Asset.includes(:current_assignment)
        assets = assets.where(status: params[:status])         if params[:status].present?
        assets = assets.where(asset_type: params[:asset_type]) if params[:asset_type].present?

        render json: assets.map { |a| asset_json(a) }, status: :ok
      end

      def show
        render json: asset_json(@asset), status: :ok
      end

      def history
        history = @asset.asset_assignment_histories
                        .includes(:employee)
                        .order(assigned_date: :desc)

        render json: history.map { |h| history_json(h) }, status: :ok
      end

      def create
        asset = Asset.new(asset_params.merge(status: "idle"))

        if asset.save
          render json: asset_json(asset), status: :created
        else
          render json: { errors: asset.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @asset.update(asset_params)
          render json: asset_json(@asset), status: :ok
        else
          render json: { errors: @asset.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      def assign
        emp_id = params[:emp_id]

        return render json: { error: "emp_id is required" }, status: :bad_request unless emp_id.present?
        return render json: { error: "Employee not found" }, status: :not_found unless Employee.exists?(emp_id: emp_id)

        unless @asset.status_idle?
          return render json: {
            error: "Asset cannot be assigned. Current status: #{@asset.status}"
          }, status: :unprocessable_entity
        end

        history = AssetAssignmentHistory.new(
          asset_id:      @asset.asset_id,
          emp_id:        emp_id,
          assigned_date: Date.today,
          returned_date: nil
        )

        success = ActiveRecord::Base.transaction do
          history.save! 
          @asset.update!(status: "assigned")
        end

        if success
          render json: {
            message:  "Asset assigned successfully",
            asset:    asset_json(@asset.reload),
            assignment: history_json(history)
          }, status: :ok
        else
          errors = history.errors.full_messages + @asset.errors.full_messages
          render json: { errors: errors }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordInvalid => e
        record = e.record
        errors = record == history ? history.errors.full_messages : @asset.errors.full_messages + history.errors.full_messages
        render json: { errors: errors.uniq }, status: :unprocessable_entity
      end
      
      def return_asset
        unless @asset.status_assigned?
          return render json: {
            error: "Asset is not currently assigned. Status: #{@asset.status}"
          }, status: :unprocessable_entity
        end

        open_assignment = @asset.current_assignment

        unless open_assignment
          return render json: { error: "No open assignment found for this asset" }, status: :unprocessable_entity
        end

        success = ActiveRecord::Base.transaction do
          open_assignment.update!(returned_date: Date.today)
          @asset.update!(status: "idle")
        end

        if success
          render json: {
            message:    "Asset returned successfully",
            asset:      asset_json(@asset.reload),
            assignment: history_json(open_assignment.reload)
          }, status: :ok
        else
          errors = open_assignment.errors.full_messages + @asset.errors.full_messages
          render json: { errors: errors }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordInvalid => e
        record = e.record
        errors = record == open_assignment ? open_assignment.errors.full_messages : @asset.errors.full_messages + open_assignment.errors.full_messages
        render json: { errors: errors.uniq }, status: :unprocessable_entity
      end

      def destroy
        unless @asset.status_idle?
          return render json: {
            error: "Only idle assets can be deleted. Current status: #{@asset.status}"
          }, status: :unprocessable_entity
        end

        @asset.destroy
        render json: { message: "Asset deleted successfully" }, status: :ok
      end

      private

      def set_asset
        @asset = Asset.find_by(asset_id: params[:id])
        render json: { error: "Asset not found" }, status: :not_found unless @asset
      end

      def asset_params
        params.require(:asset).permit(:asset_name, :asset_type, :purchase_date, :status)
      end

      def asset_json(asset)
        assigned_to = nil

        if asset.status_assigned? && asset.current_assignment&.employee
          emp = asset.current_assignment.employee
          assigned_to = { emp_id: emp.emp_id, name: emp.name }
        end

        {
          asset_id:      asset.asset_id,
          asset_name:    asset.asset_name,
          asset_type:    asset.asset_type,
          purchase_date: asset.purchase_date,
          status:        asset.status,
          assigned_to:   assigned_to
        }
      end

      def history_json(h)
        {
          emp_id:        h.emp_id,
          employee_name: h.employee&.name,
          assigned_date: h.assigned_date,
          returned_date: h.returned_date
        }
      end
    end
  end
end
