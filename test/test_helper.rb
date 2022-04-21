# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "debug"
require "rails"
require "rails/test_help"
require "action_controller/stashed_redirects"
require "minitest/autorun"

require_relative "boot/action_controller"

ENV["RAILS_ENV"] = "test"

class ActionController::StashedRedirects::Application < Rails::Application
  config.eager_load = false
  config.consider_all_requests_local = true
  config.logger = Logger.new(STDOUT)

  middleware.delete ActionDispatch::HostAuthorization
end

Rails.application.initialize!

Rails.application.routes.draw do
  resources :sessions, :users
end
