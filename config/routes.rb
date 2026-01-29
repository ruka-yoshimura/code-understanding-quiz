Rails.application.routes.draw do
  resources :quizzes, only: [:create, :show] do # クイズのリソースを定義
    member do # 特定のクイズに対するアクション
      post :answer # 回答を投稿するアクション
    end
  end
  root 'home#index'
  resources :reviews, only: [:index]
  resources :posts, except: [:index]
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  devise_scope :user do
    post 'users/guest_sign_in', to: 'users/sessions#guest_sign_in'
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
