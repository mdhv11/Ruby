# Routes (Categorized)

## Organizations
- GET    /api/v1/organizations                          api/v1/organizations#index
- POST   /api/v1/organizations                          api/v1/organizations#create
- GET    /api/v1/organizations/:id                      api/v1/organizations#show
- PATCH  /api/v1/organizations/:id                      api/v1/organizations#update
- PUT    /api/v1/organizations/:id                      api/v1/organizations#update
- DELETE /api/v1/organizations/:id                      api/v1/organizations#destroy
- GET    /api/v1/organizations/:id/summary              api/v1/organizations#summary

## Departments (within Organization)
- GET    /api/v1/organizations/:organization_id/departments                    api/v1/departments#index
- POST   /api/v1/organizations/:organization_id/departments                    api/v1/departments#create
- GET    /api/v1/organizations/:organization_id/departments/:id                api/v1/departments#show
- PATCH  /api/v1/organizations/:organization_id/departments/:id                api/v1/departments#update
- PUT    /api/v1/organizations/:organization_id/departments/:id                api/v1/departments#update
- DELETE /api/v1/organizations/:organization_id/departments/:id                api/v1/departments#destroy
- GET    /api/v1/organizations/:organization_id/departments/:id/summary        api/v1/departments#summary
- PATCH  /api/v1/organizations/:organization_id/departments/:id/assign_manager api/v1/departments#assign_manager

## Roles (within Department)
- GET    /api/v1/organizations/:organization_id/departments/:department_id/roles        api/v1/roles#index
- POST   /api/v1/organizations/:organization_id/departments/:department_id/roles        api/v1/roles#create
- GET    /api/v1/organizations/:organization_id/departments/:department_id/roles/:id    api/v1/roles#show
- PATCH  /api/v1/organizations/:organization_id/departments/:department_id/roles/:id    api/v1/roles#update
- PUT    /api/v1/organizations/:organization_id/departments/:department_id/roles/:id    api/v1/roles#update
- DELETE /api/v1/organizations/:organization_id/departments/:department_id/roles/:id    api/v1/roles#destroy

## Salary Structure (per Role)
- GET    /api/v1/organizations/:organization_id/departments/:department_id/roles/:role_id/salary_structure    api/v1/salary_structures#show
- POST   /api/v1/organizations/:organization_id/departments/:department_id/roles/:role_id/salary_structure    api/v1/salary_structures#create
- PATCH  /api/v1/organizations/:organization_id/departments/:department_id/roles/:role_id/salary_structure    api/v1/salary_structures#update
- PUT    /api/v1/organizations/:organization_id/departments/:department_id/roles/:role_id/salary_structure    api/v1/salary_structures#update
- DELETE /api/v1/organizations/:organization_id/departments/:department_id/roles/:role_id/salary_structure    api/v1/salary_structures#destroy

## Projects (within Department)
- GET    /api/v1/organizations/:organization_id/departments/:department_id/projects              api/v1/projects#index
- POST   /api/v1/organizations/:organization_id/departments/:department_id/projects              api/v1/projects#create
- GET    /api/v1/organizations/:organization_id/departments/:department_id/projects/:id          api/v1/projects#show
- PATCH  /api/v1/organizations/:organization_id/departments/:department_id/projects/:id          api/v1/projects#update
- PUT    /api/v1/organizations/:organization_id/departments/:department_id/projects/:id          api/v1/projects#update
- DELETE /api/v1/organizations/:organization_id/departments/:department_id/projects/:id          api/v1/projects#destroy
- GET    /api/v1/organizations/:organization_id/departments/:department_id/projects/:id/members  api/v1/projects#members
- POST   /api/v1/organizations/:organization_id/departments/:department_id/projects/:id/add_members       api/v1/projects#add_members
- DELETE /api/v1/organizations/:organization_id/departments/:department_id/projects/:id/remove_member      api/v1/projects#remove_member
- PATCH  /api/v1/organizations/:organization_id/departments/:department_id/projects/:id/assign_manager      api/v1/projects#assign_manager
- PATCH  /api/v1/organizations/:organization_id/departments/:department_id/projects/:id/update_status       api/v1/projects#update_status

## Leave Policies (within Department)
- GET    /api/v1/organizations/:organization_id/departments/:department_id/leave_policies        api/v1/leave_policies#index
- POST   /api/v1/organizations/:organization_id/departments/:department_id/leave_policies        api/v1/leave_policies#create
- GET    /api/v1/organizations/:organization_id/departments/:department_id/leave_policies/:id    api/v1/leave_policies#show
- PATCH  /api/v1/organizations/:organization_id/departments/:department_id/leave_policies/:id    api/v1/leave_policies#update
- PUT    /api/v1/organizations/:organization_id/departments/:department_id/leave_policies/:id    api/v1/leave_policies#update
- DELETE /api/v1/organizations/:organization_id/departments/:department_id/leave_policies/:id    api/v1/leave_policies#destroy

## Employees
- GET    /api/v1/employees                         api/v1/employees#index
- POST   /api/v1/employees/register                api/v1/employees#register
- PATCH  /api/v1/employees/:id/onboard             api/v1/employees#onboard
- GET    /api/v1/employees/:id                     api/v1/employees#show
- PATCH  /api/v1/employees/:id                     api/v1/employees#update
- PUT    /api/v1/employees/:id                     api/v1/employees#update
- DELETE /api/v1/employees/:id                     api/v1/employees#destroy
- GET    /api/v1/employees/:id/profile             api/v1/employees#profile
- PATCH  /api/v1/employees/:id/deactivate          api/v1/employees#deactivate
- PATCH  /api/v1/employees/:id/transfer            api/v1/employees#transfer
- PATCH  /api/v1/employees/:id/change_role         api/v1/employees#change_role
- GET    /api/v1/employees/:id/leave_balances      api/v1/employees#leave_balances

## Attendance (per Employee)
- GET    /api/v1/employees/:employee_id/attendances               api/v1/attendances#index
- POST   /api/v1/employees/:employee_id/attendances               api/v1/attendances#create
- GET    /api/v1/employees/:employee_id/attendances/:id           api/v1/attendances#show
- PATCH  /api/v1/employees/:employee_id/attendances/:id           api/v1/attendances#update
- PUT    /api/v1/employees/:employee_id/attendances/:id           api/v1/attendances#update
- GET    /api/v1/employees/:employee_id/attendances/summary       api/v1/attendances#summary
- POST   /api/v1/employees/:employee_id/attendances/bulk_create   api/v1/attendances#bulk_create

## Leaves (per Employee)
- GET    /api/v1/employees/:employee_id/leaves            api/v1/leaves#index
- POST   /api/v1/employees/:employee_id/leaves            api/v1/leaves#create
- GET    /api/v1/employees/:employee_id/leaves/:id        api/v1/leaves#show
- PATCH  /api/v1/employees/:employee_id/leaves/:id/approve api/v1/leaves#approve
- PATCH  /api/v1/employees/:employee_id/leaves/:id/reject  api/v1/leaves#reject
- PATCH  /api/v1/employees/:employee_id/leaves/:id/cancel  api/v1/leaves#cancel

## Performance Reviews (per Employee)
- GET    /api/v1/employees/:employee_id/performance_reviews           api/v1/performance_reviews#index
- POST   /api/v1/employees/:employee_id/performance_reviews           api/v1/performance_reviews#create
- GET    /api/v1/employees/:employee_id/performance_reviews/:id       api/v1/performance_reviews#show
- PATCH  /api/v1/employees/:employee_id/performance_reviews/:id       api/v1/performance_reviews#update
- PUT    /api/v1/employees/:employee_id/performance_reviews/:id       api/v1/performance_reviews#update
- DELETE /api/v1/employees/:employee_id/performance_reviews/:id       api/v1/performance_reviews#destroy

## Payslips (per Employee)
- GET    /api/v1/employees/:employee_id/payslips            api/v1/payslips#index
- GET    /api/v1/employees/:employee_id/payslips/:id        api/v1/payslips#show
- POST   /api/v1/employees/:employee_id/payslips/generate   api/v1/payslips#generate
- PATCH  /api/v1/employees/:employee_id/payslips/:id/disburse api/v1/payslips#disburse

## Assets
- GET    /api/v1/assets                      api/v1/assets#index
- POST   /api/v1/assets                      api/v1/assets#create
- GET    /api/v1/assets/:id                  api/v1/assets#show
- PATCH  /api/v1/assets/:id                  api/v1/assets#update
- PUT    /api/v1/assets/:id                  api/v1/assets#update
- DELETE /api/v1/assets/:id                  api/v1/assets#destroy
- GET    /api/v1/assets/:id/history          api/v1/assets#history
- PATCH  /api/v1/assets/:id/assign           api/v1/assets#assign
- PATCH  /api/v1/assets/:id/return_asset     api/v1/assets#return_asset
