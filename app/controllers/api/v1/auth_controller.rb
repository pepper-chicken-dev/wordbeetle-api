module Api
  module V1
    class AuthController < ApplicationController
      include GoogleAuthenticatable
      include GuestAuthenticatable

      def guest
        provider_uid = SecureRandom.uuid
        user = User.create!(provider: "guest", provider_uid: provider_uid, guest_expires_at: 7.days.from_now)
        token = generate_guest_token(provider_uid)

        render json: { user: user.as_json(only: [ :guest_expires_at ]), token: token }, status: :created
      end

      def google
        id_token = request.headers["Authorization"]&.split("Bearer ")&.last

        return render json: { error: "Authorization header missing" }, status: :bad_request if id_token.blank?

        payload = verify_google_token(id_token)

        return render json: { error: "Invalid ID token" }, status: :unauthorized unless payload

        email = payload["email"]
        existing_user = User.find_by(email: email) if email.present?

        if existing_user && existing_user.provider != "google"
          return render json: {
            error: "This email is already registered with #{existing_user.provider}. Please sign in with #{existing_user.provider}."
          }, status: :conflict
        end

        user = User.find_or_create_by(provider: "google", provider_uid: payload["sub"]) do |u|
          u.email = email
          u.name = payload["name"]
          u.avatar_url = payload["picture"]
        end

        render json: { user: user.as_json(only: [ :email, :name, :avatar_url ]) }, status: :ok
      end
    end
  end
end
