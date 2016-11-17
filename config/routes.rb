Rails.application.routes.draw do

  

  devise_for :users
  root to: "things#index"

  resources :things
  resources :second_steps, only: [:new, :create]

end
