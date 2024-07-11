Rails.application.routes.draw do
  devise_for :users

  root "time_regs#index"

  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  resources :onboarding, only: [ :new, :create ] do
    get :skip_and_verify_account, on: :collection
    get :edit_password, on: :collection
    put :update_password, on: :collection
  end

  post "/set_current_organization/:id" => "organizations#set_current_organization", as: :set_current_organization

  get "/locale", to: "locale#set_locale", as: "locale"

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

    resources :team_members, only: [ :index, :create, :update ] do
      post :new_modal, on: :collection
      put :edit_modal, on: :member
      post :add_to_organization, on: :collection
    end

    resources :tasks do
      post :new_modal, on: :collection
      post :edit_modal, on: :member
    end
  end

  namespace :organizations do
    resources :reports, only: [ :index ]
  end

  # PWA routes

  scope controller: :service_worker do
    get :manifest, format: :json
    get :service_worker, path: "service_worker.js"
  end
end
