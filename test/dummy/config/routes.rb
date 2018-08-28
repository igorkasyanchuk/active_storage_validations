Rails.application.routes.draw do
  resources :projects
  resources :users
  root 'users#index'
end
