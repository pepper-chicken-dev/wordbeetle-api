module Api
  module V1
    class SettingsController < ApplicationController
      before_action :set_setting, only: %i[update destroy]

      def show
        render json: SettingResource.new(current_user.effective_setting).serialize
      end

      def create
        setting = current_user.build_setting(build_setting_params)

        if setting.save
          render json: SettingResource.new(setting).serialize, status: :created
        else
          render json: { errors: setting.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        if @setting.update(build_setting_params)
          render json: SettingResource.new(@setting).serialize
        else
          render json: { errors: @setting.errors.full_messages }, status: :unprocessable_content
        end
      end

      def destroy
        @setting.destroy
        head :no_content
      end

      private

      def set_setting
        @setting = current_user.setting
        raise ActiveRecord::RecordNotFound unless @setting
      end

      def setting_params
        params.expect(
          setting: [hard_interval: %i[days hours minutes],
                    uncertain_interval: %i[days hours minutes],
                    easy_interval: %i[days hours minutes]]
        )
      end

      def build_setting_params
        permitted = setting_params
        result = {}

        %i[hard_interval uncertain_interval easy_interval].each do |attr|
          next unless permitted[attr]

          result[attr] = interval_to_duration(permitted[attr])
        end

        result
      end

      def interval_to_duration(hash)
        days = hash[:days].to_i
        hours = hash[:hours].to_i
        minutes = hash[:minutes].to_i

        days.days + hours.hours + minutes.minutes
      end
    end
  end
end
