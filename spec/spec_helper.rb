ENV["RACK_ENV"] = "test"

require "rspec"
require "capybara/rspec"

require "roda"
require "sequel/core"
require "securerandom"

require "rodauth/features/personal_access_tokens"

DB = Sequel.connect("sqlite:/", identifier_mangling: false)
DB.extension :freeze_datasets, :date_arithmetic
Sequel.extension :migration
Sequel::Migrator.run(DB, 'spec/migrate')
DB.freeze

module BaseHelpers
  class Base < Roda
    plugin :flash
    plugin :sessions, secret: SecureRandom.random_bytes(64)
    plugin :render, layout_opts: { inline: "<%= yield %>" }
    plugin :not_found do
      raise "path #{request.path_info} not found"
    end
    plugin :rodauth do
      enable :login
    end
  end

  def base_app
    Base.dup.tap { Capybara.app = _1 }
  end
end

RSpec.configure do |config|

  config.disable_monkey_patching!
  config.warnings = false
  config.order = :random
  config.include BaseHelpers

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  Kernel.srand config.seed
end
