module Api
  module V1
    class PerformanceReviewsController < ApplicationController

      before_action :set_employee
      before_action :set_review, only: [:show, :update, :destroy]

      def index
        reviews = @employee.performance_reviews.includes(:reviewer)

        if params[:year].present?
          year = params[:year].to_i
          reviews = reviews.where(review_date: Date.new(year, 1, 1)..Date.new(year, 12, 31))
        end

        reviews = reviews.where(rating: params[:rating]) if params[:rating].present?
        reviews = reviews.order(review_date: :desc)

        render json: {
          employee:       { emp_id: @employee.emp_id, name: @employee.name },
          average_rating: reviews.average(:rating)&.round(2),
          reviews:        reviews.map { |r| review_json(r) }
        }, status: :ok
      end

      def show
        render json: review_json(@review), status: :ok
      end

      def create
        review = @employee.performance_reviews.new(review_params)

        if review.save
          render json: review_json(review), status: :created
        else
          render json: { errors: review.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        requesting_reviewer = params[:requesting_reviewer_id]

        if requesting_reviewer.present? && @review.reviewer_id != requesting_reviewer
          return render json: { error: "Only the original reviewer can edit this review" }, status: :forbidden
        end

        if @review.update(review_params)
          render json: review_json(@review), status: :ok
        else
          render json: { errors: @review.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @review.destroy
        render json: { message: "Review deleted successfully" }, status: :ok
      end

      private

      def set_employee
        @employee = Employee.find_by(emp_id: params[:employee_id])
        render json: { error: "Employee not found" }, status: :not_found unless @employee
      end

      def set_review
        @review = @employee.performance_reviews.find_by(review_id: params[:id])
        render json: { error: "Review not found" }, status: :not_found unless @review
      end

      def review_params
        params.require(:performance_review).permit(:reviewer_id, :review_date, :rating, :feedback)
      end

      def review_json(review)
        {
          review_id:   review.review_id,
          emp_id:      review.emp_id,
          reviewer:    { emp_id: review.reviewer.emp_id, name: review.reviewer.name },
          review_date: review.review_date,
          rating:      review.rating,
          feedback:    review.feedback
        }
      end
    end
  end
end
 