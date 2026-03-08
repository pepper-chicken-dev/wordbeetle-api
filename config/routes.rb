Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API v1
  namespace :api do
    namespace :v1 do
      # Authentication
      post "auth/guest", to: "auth#guest"
      post "auth/google", to: "auth#google"

      # Resources
      resources :wordbooks
      resources :words
      resources :meanings
      resources :examples
      resources :settings
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
