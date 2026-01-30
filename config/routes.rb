Rails.application.routes.draw do
  resources :matches, only: [:index]

  # =========================
  # PLAYERS
  # =========================
  resources :players

  # =========================
  # COURTS
  # =========================
  resources :courts do
    member do
      patch :update_score_mode
    end
    resources :cameras, only: [:create, :destroy]
    resources :recordings, only: [:index, :show]
  end

  # =========================
  # LIVE MATCH CONTROL
  # =========================
  resources :lives, only: [:show] do
    member do
      post :start
      post :reset

      post :point_a
      post :point_b

      post :rollback

      post :back_to_score
    end
  end

  # =========================
  # HEALTH CHECK
  # =========================
  get "up" => "rails/health#show", as: :rails_health_check


  # =========================
  # ROOT
  # =========================
  root "courts#index"

end

