require "rodauth"

require_relative "personal_access_tokens/version"

module Rodauth
  Feature.define(:personal_access_tokens, :PersonalAccessTokens) do
    depends :base, :login

    auth_value_method :personal_access_tokens_table_name, :personal_access_tokens
    auth_value_method :personal_access_token_name_param, "name"
    auth_value_method :personal_access_tokens_account_id_column, :account_id
    auth_value_method :personal_access_tokens_name_column, :name
    auth_value_method :personal_access_tokens_digest_column, :digest
    auth_value_method :personal_access_tokens_error_status, 401
    auth_value_method :personal_access_tokens_route, "personal-access-tokens"
    auth_value_method :personal_access_tokens_revoke_route, "revoke"
    auth_value_method :personal_access_tokens_new_route, "new"
    auth_value_method :personal_access_tokens_error_body, "Unauthorized"
    auth_value_method :personal_access_tokens_expires_column, :expires_at
    auth_value_method :personal_access_tokens_revoked_column, :revoked_at
    auth_value_method :personal_access_tokens_validity, (60 * 60 * 24 * 365)
    auth_value_method :personal_access_tokens_header_regexp, /\ABearer: (\w+)/

    loaded_templates %w(
      personal_access_tokens
      new_personal_access_token
      revoke_personal_access_token
    )

    view "personal-access-tokens", "Personal Access Tokens", "personal_access_tokens"
    view "revoke-personal-access-token", "Revoke Personal Access Token", "revoke_personal_access_token"
    view "new-personal-access-token", "New Personal Access Token", "new_personal_access_token"

    additional_form_tags
    button "Create", "new_personal_access_token"
    button "Revoke", "revoke_personal_access_token"
    button "Back", "back_personal_access_tokens"
    redirect

    def personal_access_tokens_path
      route_path(personal_access_tokens_route)
    end

    def revoke_personal_access_token_path(id)
      "#{personal_access_tokens_path}/#{id}/#{personal_access_tokens_revoke_route}"
    end

    def new_personal_access_token_path
      "#{personal_access_tokens_path}/#{personal_access_tokens_new_route}"
    end

    def load_personal_access_token_routes
      request.on(personal_access_tokens_route) do
        check_csrf if check_csrf?
        require_account

        request.is(true) do
          personal_access_tokens_view
        end

        request.is(personal_access_tokens_new_route) do
          request.get do
            new_personal_access_token_view
          end

          request.post do
            key = create_key
            name = param(personal_access_token_name_param)
            insert_token(name, key)
            set_notice_flash "Success! New token (#{name}): #{key}"
            redirect personal_access_tokens_path
          end
        end

        request.on Integer do |id|
          request.pass unless token = account_personal_access_tokens_ds.first(id: id)

          scope.instance_variable_set(:@token, token)

          request.is(personal_access_tokens_revoke_route) do
            request.get do
              revoke_personal_access_token_view
            end

            request.post do
              account_personal_access_tokens_ds
                .where(id: id)
                .update(revoked_at: Time.now)
              set_notice_flash "Success! Token #{token[:name]} revoked"
              redirect personal_access_tokens_path
            end
          end
        end
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
        personal_access_tokens_account_id_column => account_from_session[account_id_column],
        personal_access_tokens_name_column => name,
        personal_access_tokens_digest_column => compute_hmac(key),
        personal_access_tokens_expires_column => Time.now + personal_access_tokens_validity
    end

    def template_path(page)
      path = File.join(File.dirname(__FILE__), "../../../templates", "#{page}.str")
      return super unless File.exist?(path)

      path
    end

    def account_personal_access_tokens_ds
      DB[personal_access_tokens_table_name]
        .where(personal_access_tokens_account_id_column => account_from_session[account_id_column])
    end

    def create_key
      SecureRandom.alphanumeric(20)
    end

    def account_personal_access_tokens
      account_personal_access_tokens_ds
        .where(personal_access_tokens_revoked_column => nil)
        .all
    end

    def token_valid?(header)
      return false unless header
      return false unless key = header[personal_access_tokens_header_regexp, 1]

      !!DB[personal_access_tokens_table_name]
        .where(Sequel::CURRENT_TIMESTAMP < personal_access_tokens_expires_column)
        .where(personal_access_tokens_revoked_column => nil)
        .first(personal_access_tokens_digest_column => compute_hmac(key))
    end

  end
end
