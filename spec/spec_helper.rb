# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rodauth/features/pat"

require "capybara"
require "capybara/dsl"
require "minitest/autorun"

require "sequel"
require "roda"
require "rodauth/features/pat"
require "rodauth/version"
