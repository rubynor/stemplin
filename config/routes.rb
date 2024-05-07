Rails.application.routes.draw do
  devise_for :users

  root "time_regs#index"

  resources :onboarding, only: [ :new, :create ] do
    get :skip_and_verify_account, on: :collection
    get :edit_password, on: :collection
    put :update_password, on: :collection
  end

  post "/set_current_organization/:id" => "organizations#set_current_organization", as: :set_current_organization

  get "/locale", to: "locale#set_locale", as: "locale"

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

  namespace :workspace do
    resources :projects do
      post :import_modal, on: :collection
      post :new_modal, on: :collection
      put :edit_modal, on: :member

      scope module: :projects do
        resources :assigned_tasks do
          post :new_modal, on: :member
          post :edit_modal, on: :member
        end

        resource :tasks do
          post :new_modal, on: :member
        end
      end
    end

    resources :clients do
      post :new_modal, on: :collection
      post :edit_modal, on: :member
    end

    resources :teams, only: [ :index, :create ] do
      post :new_modal, on: :collection
    end

    resources :tasks do
      post :new_modal, on: :collection
      post :edit_modal, on: :member
    end
  end

  namespace :organizations do
    resources :reports, only: [ :index ]
  end
end
