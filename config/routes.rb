require "sidekiq/web"

Rails.application.routes.draw do
  use_doorkeeper do
    skip_controllers :applications, :authorized_applications
  end

  post "/oauth/register", to: "oauth/dynamic_registration#create"
  get "/.well-known/oauth-protected-resource", to: "oauth/protected_resource_metadata#show"
  get "/.well-known/oauth-authorization-server", to: "oauth/authorization_server_metadata#show"

  devise_for :users, controllers: {
    invitations: "users/invitations",
    registrations: "users/registrations",
    passwords: "users/passwords"
  }

  authenticated :user do
    root to: "time_regs#index", as: :authenticated_root
  end

  root to: redirect("users/sign_in")

  get "privacy-policy", to: "privacy_policy#index", as: :privacy_policy

  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :organizations, only: %i[index show]
      resources :clients, only: %i[index show create update destroy]
      resources :projects, only: %i[index show create update destroy]
      resources :tasks, only: %i[index show]
      resources :time_regs, only: %i[index show create update destroy] do
        resource :timer, only: :update
      end
      resources :users, only: %i[index show] do
        get :me, on: :collection
      end
      resource :api_token, only: :update
      resources :reports, only: %i[index] do
        get :detailed, on: :collection
      end
    end
  end

  resources :onboarding, only: [ :new, :create ]

  post "/set_current_organization/:id" => "organizations#set_current_organization", as: :set_current_organization

  get "/locale", to: "locale#set_locale", as: "locale"

  resources :clients

  resources :time_regs do
    patch :toggle_active
    resources :copies, only: [ :create ], controller: "time_reg/copies"
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
    end

    scope module: :projects do
      resources :assigned_tasks, only: [] do
        post :add_modal, on: :collection
        post :add, on: :collection
        delete :remove, on: :collection
      end
    end

    resources :clients, except: [ :index ] do
      post :new_modal, on: :collection
      post :edit_modal, on: :member
    end

    resources :team_members, only: [ :index, :create, :update ] do
      get :invite_users, on: :collection
      put :edit_modal, on: :member
    end

    resource :settings, only: [ :show, :edit, :update ]
  end

  resources :reports, only: [ :index ]
  get "reports/detailed", to: "reports#detailed", as: :detailed_reports

  # Project invitation routes
  # get "project_invitations/:token/accept", to: "project_invitations#show", as: :accept_project_invitation
  # post "project_invitations/:token/accept", to: "project_invitations#accept"
  # post "project_invitations/:token/reject", to: "project_invitations#reject", as: :reject_project_invitation


  # PWA routes

  scope controller: :service_worker do
    get :manifest, format: :json
    get :service_worker, path: "service_worker.js"
  end

  get "robots.txt", to: "robots#index"

  authenticate :user, ->(u) { u.is_super_admin? } do
    mount Sidekiq::Web, at: "sidekiq"
  end

  resource :onboarding_wizard, only: [] do
    get "skip", to: "onboarding_wizard#skip"
  end
  resources :onboarding_wizard, only: [ :show, :update ], controller: "onboarding_wizard"
end
