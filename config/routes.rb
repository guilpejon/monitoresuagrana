Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end
  root "pages#showcase"

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
  resources :payees
  resources :possessions
  get "/forecast", to: "forecast#index", as: :forecast

  namespace :user do
    resource :settings, only: [ :edit, :update ]
  end

  get "/locale/:locale", to: "locales#set", as: :set_locale

  get "up" => "rails/health#show", as: :rails_health_check
end
