Rails.application.routes.draw do
  devise_for :users

  root 'time_regs#index'

  resources :project_reports do
    patch :update_group
    collection do
      get 'update_projects_select'
      get 'update_members_checkboxes'
      get 'update_tasks_checkboxes'
      post 'export'
    end
  end

  resources :user_reports do
    patch :update_group
    collection do
      post 'export'
      get 'update_projects_checkboxes'
      get 'update_tasks_checkboxes'
    end
  end

  resources :clients

  resources :tasks

  match 'projects/import' => 'projects#import', :via => :post
  resources :time_regs do
    patch :toggle_active
    collection do
      get 'export'
      post 'import'
      get 'update_tasks_select'
      get 'new_modal', to: 'time_regs#new', as: :new_modal
    end
  end

  resources :projects do
    resources :memberships
    resources :assigned_tasks
    get 'export', to: 'projects#export', as: 'export_project_time_reg'
  end
end
