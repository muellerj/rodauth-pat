# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "capybara"
require "capybara/dsl"
require "minitest/autorun"

Capybara.exact = true

require "roda"
require "sequel/core"
require "rodauth/features/pat"

DB = Sequel.connect("sqlite:/", identifier_mangling: false)
DB.extension :freeze_datasets, :date_arithmetic

Base = Class.new(Roda)
Base.plugin :flash
Base.plugin :render, layout_opts: { path: 'spec/views/layout.str' }
Base.plugin(:not_found) { raise "path #{request.path_info} not found" }

class Base
  attr_writer :title
end

