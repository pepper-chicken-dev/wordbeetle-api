Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # API v1
  namespace :api do
    namespace :v1 do
      # Authentication
      post 'auth/guest', to: 'auth#guest'
      post 'auth/google', to: 'auth#google'

      # Resources
      resources :wordbooks do
        namespace :test do
          resources :words, only: [:index]
        end
        resources :words do
          resources :meanings do
            resources :examples
          end
        end
      end
      resource :setting, only: %i[show create update destroy]
    end
  end

  # Error handling (must be last)
  match '/:status', to: 'errors#show', via: :all, constraints: { status: /\d{3}/ }
end
