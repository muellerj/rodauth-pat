ENV["RACK_ENV"] = "test"

require "rspec"
require "capybara/rspec"

require "roda"
require "sequel/core"
require "securerandom"

require "rodauth/features/personal_access_tokens"

DB = Sequel.connect("sqlite:/", identifier_mangling: false)
Sequel.extension :migration
Sequel::Migrator.run(DB, 'spec/migrate')
DB.freeze

module BaseHelpers

  SECRET = SecureRandom.base64(64)

  class Base < Roda
    plugin :flash
    plugin :sessions, secret: SECRET
    plugin :render, layout_opts: { inline: <<~EOS }
      <%= flash["notice"] %>
      <%= flash["error"] %>
      <%= yield %>
    EOS
    plugin :not_found do
      raise "path #{request.path_info} not found"
    end
    plugin :rodauth do
      enable :login
      account_password_hash_column :ph
      login_return_to_requested_location? true
      hmac_secret SECRET
    end
  end

  def base_app
    Base.dup.tap { Capybara.app = _1 }
  end

  def login
    fill_in "Login", with: "foo@example.com"
    fill_in "Password", with: "0123456789"
    click_button "Login"
  end

  def digest_for(key)
    OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, SECRET, key)
  end
end

RSpec.configure do |config|

  config.disable_monkey_patching!
  config.warnings = false
  config.order = :random
  config.include BaseHelpers
  config.backtrace_exclusion_patterns = [
    /gems\//,
    /spec\/spec_helper\.rb/,
  ]

  config.around(:each) do |example|
    DB.transaction(rollback: :always, auto_savepoint: true) do
      hsh = BCrypt::Password.create("0123456789", cost: BCrypt::Engine::MIN_COST)
      DB[:accounts].insert(email: "foo@example.com", ph: hsh)
      example.run
    end
  end

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  Kernel.srand config.seed
end
