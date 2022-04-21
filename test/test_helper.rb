# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "action_controller"
require "action_controller/stashed_redirects"

require "action_dispatch/testing/integration"

require "rails"
require "rails/application"
require "minitest/autorun"

require_relative "boot/action_controller"

class ActionController::StashedRedirects::Application < Rails::Application
  config.eager_load = false
end

Rails.application.initialize!

Rails.application.routes.draw do
  resources :sessions, :users
end
