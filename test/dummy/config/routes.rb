Rails.application.routes.draw do
  resources :ratio_models
  resources :projects
  resources :users
  root 'users#index'
end
