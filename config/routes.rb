Rails.application.routes.draw do
  devise_for :users

  root "time_regs#index"

  resources :project_reports do
    patch :update_group
    collection do
      get "update_projects_select"
      get "update_members_checkboxes"
      get "update_tasks_checkboxes"
      post "export"
      get ":id/detailed", to: "project_reports#detailed", as: :detailed_project_report
    end
  end

  resources :user_reports do
    patch :update_group
    collection do
      post "export"
      get "update_projects_checkboxes"
      get "update_tasks_checkboxes"
    end
  end

  resource :report, only: [ :show, :update ]

  resources :clients

  resources :tasks

  match "projects/import" => "projects#import", :via => :post
  resources :time_regs do
    patch :toggle_active
    collection do
      get "export"
      post "import"
      get "update_tasks_select"
    end
    post :new_modal, on: :collection
    put :edit_modal, on: :member
  end

  resources :projects, except: [ :index ] do
    resources :memberships
    resources :assigned_tasks
    get "export", to: "projects#export", as: "export_project_time_reg"
  end
end
