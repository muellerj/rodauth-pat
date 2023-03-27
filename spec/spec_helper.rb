ENV["RACK_ENV"] = "test"

require "rspec"
require "capybara/rspec"

require "roda"
require "sequel/core"
require "rodauth/features/pat"

DB = Sequel.connect("sqlite:/", identifier_mangling: false)
DB.extension :freeze_datasets, :date_arithmetic

module BaseHelpers
  class Base < Roda
    plugin :flash
    plugin :sessions, secret: "foo-bar" * 20
    plugin :render, layout_opts: { inline: "<%= yield %>" }
    plugin :not_found do
      raise "path #{request.path_info} not found"
    end
    plugin :rodauth do
      enable :login, :logout
    end
  end

  def base_app
    Base.dup.tap { Capybara.app = _1 }
  end
end

RSpec.configure do |config|

  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  config.include BaseHelpers

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  Kernel.srand config.seed
end
