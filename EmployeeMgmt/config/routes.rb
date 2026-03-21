Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do

      # Organizations → Departments → Roles → Projects → Policies

      resources :organizations do
        member { get :summary }

        resources :departments do
          member do
            get   :summary
            patch :assign_manager
          end

          resources :roles do
            resource :salary_structure, only: [:show, :create, :update, :destroy]
          end

          resources :projects do
            member do
              get    :members
              post   :add_members
              delete :remove_member
              patch  :assign_manager
              patch  :update_status
            end
          end

          resources :leave_policies

        end
      end

      # Employees (top-level, filter by dept/org via query params)
      resources :employees do
        collection {post :register} 
        member do
          patch :onboard
          get   :profile
          patch :deactivate
          patch :transfer
          patch :change_role
          get   :leave_balances
        end

        resources :attendances, only: [:index, :show, :create, :update] do
          collection do
            get  :summary
            post :bulk_create
          end
        end

        resources :leaves, only: [:index, :show, :create] do
          member do
            patch :approve
            patch :reject
            patch :cancel
          end
        end

        resources :performance_reviews, only: [:index, :show, :create, :update, :destroy]

        resources :payslips, only: [:index, :show] do
          collection { post :generate }
          member     { patch :disburse }
        end

      end

      # Assets (org-wide, no parent scope)
      resources :assets do
        member do
          get   :history
          patch :assign
          patch :return_asset
        end
      end

    end
  end
end