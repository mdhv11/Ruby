module Api
  module V1
    class OrganizationsController < ApplicationController

      before_action :set_organization, only: [:show, :update, :destroy, :summary]

      #for admin use
      def index
        organizations = Organization.all
        render json: organizations, status: :ok
      end

      def show
        render json: @organization, status: :ok
      end

      def summary
        render json: {
          org_id:           @organization.org_id,
          name:             @organization.name,
          industry:         @organization.industry,
          ceo:              @organization.ceo,
          address:          @organization.address,
          department_count: @organization.departments.count,
          role_count:       @organization.roles.count,
          employee_count:   @organization.employees.count
        }, status: :ok
      end

      def create
        organization = Organization.new(organization_params)

        if organization.save
          render json: organization, status: :created
        else
          render json: { errors: organization.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @organization.update(organization_params)
          render json: @organization, status: :ok
        else
          render json: { errors: @organization.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @organization.destroy
          render json: { message: "Organization deleted successfully" }, status: :ok
        else
          render json: { errors: @organization.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_organization
        @organization = Organization.find_by(org_id: params[:id])
        render json: { error: "Organization not found" }, status: :not_found unless @organization
      end

      def organization_params
        params.require(:organization).permit(:name, :industry, :ceo, :address)
      end
    end
  end
end