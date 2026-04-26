module Api
  module V1
    class UsersController < ApplicationController
      def destroy
        current_user.destroy!
        head :no_content
      end
    end
  end
end
