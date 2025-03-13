Rails.application.routes.draw do
  namespace :api do
    devise_for :users, controllers: {
      sessions: "api/sessions",
      registrations: "api/registrations"
    }

    resources :users
    resources :projects do
      resources :tasks, only: [ :index, :create, :show, :update, :destroy ]
    end
  end
end
