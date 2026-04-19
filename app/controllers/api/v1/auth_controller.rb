module Api
  module V1
    class AuthController < ApplicationController
      skip_before_action :authenticate_user!

      def guest
        user = User.create!(provider: 'guest', guest_expires_at: 7.days.from_now)
        token = JsonWebToken.encode(user.id, expires_at: user.guest_expires_at)

        user_json = JSON.parse(UserResource.new(user, params: { type: :guest }).serialize)
        render json: { user: user_json, token: token }, status: :created
      end

      def google
        id_token = request.headers['Authorization']&.split('Bearer ')&.last

        raise BadRequestError, 'Authorization header missing' if id_token.blank?

        payload = GoogleIdToken.decode(id_token)

        return handle_guest_migration(payload) if params[:guest_token].present?

        email = payload['email']
        existing_user = User.find_by(email: email) if email.present?

        if existing_user && existing_user.provider != 'google'
          raise ConflictError, "This email is already registered with #{existing_user.provider}. " \
                               "Please sign in with #{existing_user.provider}."
        end

        begin
          user = User.find_or_create_by(provider: 'google', provider_uid: payload['sub']) do |u|
            u.email = email
            u.name = payload['name']
            u.avatar_url = payload['picture']
          end
        rescue ActiveRecord::RecordNotUnique
          Rails.logger.warn(
            "Google auth race condition: RecordNotUnique for provider_uid=#{payload['sub']}, retrying find"
          )
          user = User.find_by!(provider: 'google', provider_uid: payload['sub'])
        end

        render json: { user: JSON.parse(UserResource.new(user, params: { type: :google }).serialize),
                       token: JsonWebToken.encode(user.id) },
               status: :ok
      end

      private

      def handle_guest_migration(google_payload)
        guest_user = User.find_by_token(params[:guest_token])
        raise AuthenticationError, 'Invalid guest token' unless guest_user&.guest?

        result = guest_user.migrate_to_google(google_payload)
        raise UnprocessableEntityError, result.error unless result.success?

        user_json = JSON.parse(UserResource.new(result.user, params: { type: :google }).serialize)
        render json: { user: user_json, token: JsonWebToken.encode(result.user.id) },
               status: :ok
      end
    end
  end
end
