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

ONE_YEAR = 60 * 60 * 24 * 365

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
      enable :internal_request
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

  def insert_token(name:, user:, key: "foobar", expires_at: nil, revoked_at: nil)
    DB[:personal_access_tokens].insert \
      account_id: user[:id],
      name: name,
      digest: compute_hmac(key),
      expires_at: expires_at || Time.new + ONE_YEAR,
      revoked_at: revoked_at
  end

  def compute_hmac(key)
    app.rodauth.internal_request_eval { compute_hmac(key) }
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
