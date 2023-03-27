require "rspec"
require "capybara/rspec"

require "roda"
require "sequel/core"
require "rodauth/features/pat"

DB = Sequel.connect("sqlite:/", identifier_mangling: false)
DB.extension :freeze_datasets, :date_arithmetic

class Base < Roda
  plugin :flash
  plugin :render, layout_opts: { path: 'spec/views/layout.str' }
  plugin :not_found do
    raise "path #{request.path_info} not found"
  end
end

def app
  Base.tap { Capybara.app = _1 }
end

RSpec.configure do |config|

  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  Kernel.srand config.seed
end

ENV['RACK_ENV'] = 'test'
