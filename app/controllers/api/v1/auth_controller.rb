module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_user!

      def guest
        user = User.create!(provider: 'guest', guest_expires_at: 7.days.from_now)
        token = JsonWebToken.encode(user.id, expires_at: user.guest_expires_at)

        render json: { user: user.as_json(only: [:guest_expires_at]), token: token }, status: :created
      end

      def google
        id_token = request.headers['Authorization']&.split('Bearer ')&.last

        return render json: { error: 'Authorization header missing' }, status: :bad_request if id_token.blank?

        payload = GoogleIdToken.decode(id_token)

        return handle_guest_migration(payload) if params[:guest_token].present?

        email = payload['email']
        existing_user = User.find_by(email: email) if email.present?

        if existing_user && existing_user.provider != 'google'
          message = "This email is already registered with #{existing_user.provider}. " \
                    "Please sign in with #{existing_user.provider}."
          return render json: { error: message }, status: :conflict
        end

        user = User.find_or_create_by(provider: 'google', provider_uid: payload['sub']) do |u|
          u.email = email
          u.name = payload['name']
          u.avatar_url = payload['picture']
        end

        render json: { user: user.as_json(only: %i[email name avatar_url]), token: JsonWebToken.encode(user.id) },
               status: :ok
      end

      private

      def handle_guest_migration(google_payload)
        guest_user = User.find_by_token(params[:guest_token])

        return render json: { error: 'Invalid guest token' }, status: :unauthorized unless guest_user&.guest?

        result = guest_user.migrate_to_google(google_payload)

        if result.success?
          user_json = result.user.as_json(only: %i[email name avatar_url])
          render json: { user: user_json, token: JsonWebToken.encode(result.user.id) },
                 status: :ok
        else
          render json: { error: result.error }, status: :unprocessable_content
        end
      end
    end
  end
end
