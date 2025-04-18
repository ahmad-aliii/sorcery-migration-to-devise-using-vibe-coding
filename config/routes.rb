Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Devise routes
  devise_for :users

  # Root route
  root "pages#home"

  # Authentication routes
  get "login" => "user_sessions#new", as: :login
  post "login" => "user_sessions#create"
  delete "logout" => "user_sessions#destroy", as: :logout
  get "signup" => "users#new", as: :signup
  post "signup" => "users#create"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
