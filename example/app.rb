require "roda"
require "sequel/core"
require "securerandom"
require "net/http"
require "bcrypt"
require "digest/sha1"

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

DB = Sequel.connect("sqlite:/", identifier_mangling: false)
Sequel.extension :migration
Sequel::Migrator.run(DB, File.expand_path("../spec/migrate", __dir__))

hash = BCrypt::Password.create("password", cost: BCrypt::Engine::MIN_COST)
DB[:accounts].insert_conflict(target: :email).insert(email: "foo@bar.com", ph: hash)

class PersonalAccessTokenApp < Roda
  SECRET = SecureRandom.base64(64)

  plugin :flash
  plugin :common_logger
  plugin :sessions, secret: SECRET
  plugin :render, layout_opts: { inline: <<~EOS }
    <%= flash["notice"] %>
    <%= flash["error"] %>
    <%= yield %>
  EOS

  plugin :rodauth do
    db DB
    enable :login
    enable :personal_access_tokens
    account_password_hash_column :ph
    login_return_to_requested_location? true
    hmac_secret SECRET
  end

  plugin :not_found do
    "Not Found: #{request.path_info}"
  end

  route do |r|
    r.rodauth
    rodauth.load_personal_access_token_routes

    r.root do
      view inline: <<~HTML
        This is the root path!<br>
        <a href="/personal-access-tokens">Tokens</a>
      HTML
    end

  end
end

DB.freeze

if $0 == __FILE__
  require "rackup"

  Rackup::Server.start \
    app: PersonalAccessTokenApp,
    Port: 9292
end
