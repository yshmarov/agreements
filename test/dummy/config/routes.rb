# frozen_string_literal: true

Rails.application.routes.draw do
  get "/protected", to: "protected#index"
  post "/protected", to: "protected#create"
  get "/agreement", to: "acceptances#show"
  post "/agreement", to: "acceptances#create"
  get "/return-path", to: "acceptances#return_path"
end
