# frozen_string_literal: true

require "test_helper"

class ActionController::TestStashedRedirects < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::ActionController::StashedRedirects::VERSION
  end
end
