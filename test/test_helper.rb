# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "action_controller"
require "action_controller/stashed_redirects"

require "action_dispatch/testing/integration"

require "minitest/autorun"

require_relative "boot/action_controller"
