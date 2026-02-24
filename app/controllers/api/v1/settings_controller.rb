module Api
  module V1
    class SettingsController < ApplicationController
      before_action :set_setting, only: [ :show, :update, :destroy ]

      def index
        settings = Setting.all
        render json: settings
      end

      def show
        render json: @setting
      end

      def create
        setting = Setting.new(setting_params)

        if setting.save
          render json: setting, status: :created
        else
          render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @setting.update(setting_params)
          render json: @setting
        else
          render json: { errors: @setting.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @setting.destroy
        head :no_content
      end

      private

      def set_setting
        @setting = Setting.find(params[:id])
      end

      def setting_params
        params.require(:setting).permit(:user_id, :hard_interval_days, :uncertain_interval_days, :easy_interval_days)
      end
    end
  end
end
