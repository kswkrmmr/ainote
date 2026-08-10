Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    get "health", to: "health#show"
    resources :users, only: [ :create ]
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"
    get "me", to: "me#show"
    resources :rooms, only: [ :index, :show, :create ] do
      resources :invitations, only: [ :create ]
    end
    get "invitations/:token", to: "invitations#show"
  end
  # Defines the root path route ("/")
  # root "posts#index"
end
