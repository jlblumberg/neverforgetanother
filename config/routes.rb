Rails.application.routes.draw do
  get "home/index"
  root "home#index"
  
  resources :reminders do
    member do
      post :cancel
      post :uncancel
    end
  end
  
  get '/settings', to: 'settings#show', as: :settings
  patch '/settings/timezone', to: 'settings#update_timezone', as: :update_timezone
  patch '/settings/phone', to: 'settings#update_phone', as: :update_phone
  
  # OAuth routes - POST for initiation (CSRF-safe), GET for callback
  post '/auth/:provider', to: 'omniauth#passthru', as: :omniauth_authorize
  get '/auth/:provider/callback', to: 'sessions#create', as: :omniauth_callback
  get '/auth/failure', to: 'sessions#failure'
  delete '/logout', to: 'sessions#destroy', as: :logout

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
