Rails.application.routes.draw do
  get "home/index"
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations'
  }

  # Development email preview
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Location setup
  get 'setup_location', to: 'location_setup#show'
  post 'setup_location', to: 'location_setup#create'
  
  # Ward-centric structure
  resources :wards, only: [:index, :show] do
    member do
      get :info
      get :news
    end
    resources :prabhags, only: [:index, :show]
    resources :tweets, only: [:create]
    scope module: :wards do
      resources :facilities, only: [:index] do
        collection do
          get :scorecard
        end
      end
      resources :changes, only: [:index]
    end
  end
  
  # Legacy prabhag routes (for backward compatibility)
  resources :prabhags, only: [:index, :show] do
    member do
      post :assign
      get :trace
      post :submit
    end
  end
  
  namespace :admin do
    resources :prabhags, only: [:index, :show] do
      member do
        get 'boundaries', to: 'prabhags#boundary_review'
      end
      resources :boundaries, only: [:show, :edit, :update] do
        member do
          post :approve
          post :reject
        end
      end
    end
    resources :boundaries do
      member do
        post :approve
        post :reject
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
end
