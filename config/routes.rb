Rails.application.routes.draw do
  devise_for :users

  root "dashboard#index"

  resources :expenses
  resources :incomes
  resources :credit_cards
  resources :investments do
    member do
      post :refresh_price
    end
    collection do
      post :refresh_all_prices
    end
  end
  resources :bank_accounts do
    collection do
      post :refresh_cdi_rate
    end
  end
  resources :categories
  get "/forecast", to: "forecast#index", as: :forecast

  namespace :user do
    resource :settings, only: [:edit, :update]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
