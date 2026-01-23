Rails.application.routes.draw do
  get "recordings/index"
  get "recordings/show"

  resources :courts, only: [:index, :create] do
    resources :cameras, only: [:create, :destroy]
    resources :recordings, only: [:index, :show]
  end

  resources :lives, only: [:show] do
    member do
      post :point_a
      post :point_b

      post :minus_a
      post :minus_b

      post :start
      post :reset

      post :back_to_score
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
  root "courts#index"
end
