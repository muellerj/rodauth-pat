# Personal Access Tokens for Rodauth

This is an extension to the `rodauth` gem which implements Personal
Access Tokens for an authorization server.

## Installation

Add this line to your application's Gemfile:

``` ruby
gem 'rodauth-pat'
```

And then execute:

``` sh
$ bundle install
```

Or install it yourself as:

``` sh
$ gem install rodauth-pat
```

## Usage

After setting up basic `rodauth`, you can enable the feature:

``` ruby
plugin :rodauth do
  enable :login, :personal_access_tokens
end

# then, inside roda

route do |r|
  r.rodauth

  # This will setup 3 routes for management of the Personal Access Tokens:
  # There are not strictly required for operation of #require_token_authentication
  #
  #   * /personal-access-tokens             Show non-revoked tokens
  #   * /personal_access_tokens/:id/revoke  Revoke existing tokens
  #   * /personal_access_tokens/new         Create new tokens
  rodauth.load_personal_access_token_routes

  r.get "public" do
    "public!"
  end

  r.get "protected" do
    rodauth.require_authentication
    "secret!"
  end

  r.get "api" do
    rodauth.require_token_authentication
    "secret with api!"
  end
end
```
