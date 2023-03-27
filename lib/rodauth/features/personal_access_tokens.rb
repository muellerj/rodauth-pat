require "rodauth"

require_relative "personal_access_tokens/version"

module Rodauth
	Feature.define(:personal_access_tokens, :PersonalAccessTokens) do
		# Shortcut for defining auth value methods with static values
		auth_value_method :method_name, 1 # method_value

		auth_value_methods # one argument per auth value method

		auth_methods # one argument per auth method

		route do |r|
			# This block is taken for requests to the feature's route.
			# This block is evaluated in the scope of the Rodauth::Auth instance.
			# r is the Roda::RodaRequest instance for the request

			r.get do
			end

			r.post do
			end
		end

    def require_token_authentication
      request.halt [ 401, {}, "Unauthorized" ]
    end

	end
end
