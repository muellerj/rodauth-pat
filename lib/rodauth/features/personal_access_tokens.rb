require "rodauth"

require_relative "personal_access_tokens/version"

module Rodauth
	Feature.define(:personal_access_tokens, :PersonalAccessTokens) do
    depends :base, :login

		auth_value_method :personal_access_tokens_table_name, :personal_access_tokens
		auth_value_method :personal_access_tokens_id_column, :id
		auth_value_method :personal_access_tokens_key_column, :key
		auth_value_method :personal_access_tokens_error_status, 401
		auth_value_method :personal_access_tokens_error_body, "Unauthorized"
		auth_value_method :personal_access_tokens_expires_column, :expires_at
		auth_value_method :personal_access_tokens_validity, (60 * 60 * 24 * 365)
		auth_value_method :personal_access_tokens_header_regexp, /\ABearer: (\w+)/

		route do |r|
			r.get do
        "my tokens"
			end

			r.post do
        require_authentication
        token = random_token
        insert_token(current_account, token)
        token
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

    def insert_token(account, token)
      DB[personal_access_tokens_table_name].insert \
        personal_access_tokens_id_column => account[personal_access_tokens_id_column],
        personal_access_tokens_key_column => token,
        personal_access_tokens_expires_column => Time.now + personal_access_tokens_validity
    end

    def token_valid?(header)
      return false unless header
      return false unless key = header[personal_access_tokens_header_regexp, 1]

      !!DB[personal_access_tokens_table_name]
        .where(Sequel::CURRENT_TIMESTAMP < personal_access_tokens_expires_column)
        .first(personal_access_tokens_key_column => key)
    end

	end
end
