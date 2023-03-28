require "rodauth"

require_relative "personal_access_tokens/version"

module Rodauth
  Feature.define(:personal_access_tokens, :PersonalAccessTokens) do
    depends :base, :login

    auth_value_method :personal_access_tokens_table_name, :personal_access_tokens
    auth_value_method :personal_access_token_name_param, "name"
    auth_value_method :personal_access_tokens_id_column, :id
    auth_value_method :personal_access_tokens_name_column, :name
    auth_value_method :personal_access_tokens_key_column, :key
    auth_value_method :personal_access_tokens_error_status, 401
    auth_value_method :personal_access_tokens_error_body, "Unauthorized"
    auth_value_method :personal_access_tokens_expires_column, :expires_at
    auth_value_method :personal_access_tokens_revoked_column, :revoked_at
    auth_value_method :personal_access_tokens_validity, (60 * 60 * 24 * 365)
    auth_value_method :personal_access_tokens_header_regexp, /\ABearer: (\w+)/

    loaded_templates %w'personal_access_tokens new_personal_access_token revoke_personal_access_token'
    view "personal-access-tokens", "Personal Access Tokens", "personal_access_tokens"
    view "new-personal-access-token", "New Personal Access Token", "new_personal_access_token"
    view "revoke-personal-access-token", "Revoke Personal Access Token", "revoke_personal_access_token"

    additional_form_tags
    button "Create", "new_personal_access_token"
    button "Revoke", "revoke_personal_access_token"
    button "Back", "back_personal_access_tokens"
    redirect

    route(:personal_access_tokens) do |r|
      require_account

      r.get do
        personal_access_tokens_view
      end

    end

    route(:new_personal_access_token) do |r|
      require_account

      r.get do
        new_personal_access_token_view
      end

      r.post do
        key = random_key
        name = param(personal_access_token_name_param)
        insert_token(name, key)
        set_notice_flash "Success! New token (#{name}): #{key}"
        redirect personal_access_tokens_path
      end
    end

    route(:revoke_personal_access_token) do |r|
      require_account

      r.get do
        revoke_personal_access_token_view
      end

      r.post do
        # Revoke token and redirect
      end
    end

    def require_token_authentication
      return if token_valid?(request.env["HTTP_AUTHENTICATION"])

      request.halt [
        personal_access_tokens_error_status,
        {},
        personal_access_tokens_error_body
      ]
    end

    def insert_token(name, key)
      DB[personal_access_tokens_table_name].insert \
        personal_access_tokens_id_column => account_from_session[personal_access_tokens_id_column],
        personal_access_tokens_name_column => name,
        personal_access_tokens_key_column => key,
        personal_access_tokens_expires_column => Time.now + personal_access_tokens_validity
    end

    def template_path(page)
      path = File.join(File.dirname(__FILE__), "../../../templates", "#{page}.str")
      return super unless File.exist?(path)

      path
    end

    def account_personal_access_tokens
      DB[personal_access_tokens_table_name]
        .where(personal_access_tokens_id_column => account_from_session[account_id_column])
        .all
    end

    def token_valid?(header)
      return false unless header
      return false unless key = header[personal_access_tokens_header_regexp, 1]

      !!DB[personal_access_tokens_table_name]
        .where(Sequel::CURRENT_TIMESTAMP < personal_access_tokens_expires_column)
        .where(personal_access_tokens_revoked_column => nil)
        .first(personal_access_tokens_key_column => key)
    end

  end
end
