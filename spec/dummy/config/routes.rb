# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :simple_form do
    resources :posts
    resources :articles
  end

  namespace :standard do
    resources :posts
    resources :articles
  end

  root to: "simple_form/posts#index"
end
