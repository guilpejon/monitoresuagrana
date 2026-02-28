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
  resources :categories
  get "/forecast", to: "forecast#index", as: :forecast

  get "up" => "rails/health#show", as: :rails_health_check
end
