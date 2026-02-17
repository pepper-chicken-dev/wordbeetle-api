module Api
  module V1
    class AuthController < ApplicationController
      include GoogleAuthenticatable

      def google
        id_token = request.headers["Authorization"]&.split("Bearer ")&.last

        return render json: { error: "Authorization header missing" }, status: :bad_request if id_token.blank?

        payload = verify_google_token(id_token)

        return render json: { error: "Invalid ID token" }, status: :unauthorized unless payload

        user = User.find_or_create_by(provider: "google", provider_uid: payload["sub"]) do |u|
          u.email = payload["email"]
          u.name = payload["name"]
          u.avatar_url = payload["picture"]
        end

        render json: { user: user }, status: :ok
      end
    end
  end
end
