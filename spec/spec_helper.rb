require "capybara"
require "capybara/dsl"
require "rspec"

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

RSpec.configure do |config|

  config.disable_monkey_patching!
  config.warnings = true
  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.order = :random

  Kernel.srand config.seed
end

ENV['RACK_ENV'] = 'test'
