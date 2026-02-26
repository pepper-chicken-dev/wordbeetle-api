module Api
  module V1
    class SettingsController < ApplicationController
      before_action :set_setting, only: [ :show, :update, :destroy ]

      def index
        settings = Setting.all
        render json: settings.map { |s| setting_response(s) }
      end

      def show
        render json: setting_response(@setting)
      end

      def create
        setting = Setting.new(build_setting_params)

        if setting.save
          render json: setting_response(setting), status: :created
        else
          render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @setting.update(build_setting_params)
          render json: setting_response(@setting)
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
        params.require(:setting).permit(
          :user_id,
          hard_interval: [ :days, :hours, :minutes ],
          uncertain_interval: [ :days, :hours, :minutes ],
          easy_interval: [ :days, :hours, :minutes ]
        )
      end

      def build_setting_params
        permitted = setting_params
        result = permitted.slice(:user_id).to_h

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

      def setting_response(setting)
        setting.as_json(except: %i[hard_interval uncertain_interval easy_interval]).merge(
          hard_interval: duration_to_hash(setting.hard_interval),
          uncertain_interval: duration_to_hash(setting.uncertain_interval),
          easy_interval: duration_to_hash(setting.easy_interval)
        )
      end

      def duration_to_hash(duration)
        return nil if duration.blank?

        total_seconds = duration.to_i
        days = total_seconds / 86400
        hours = (total_seconds % 86400) / 3600
        minutes = (total_seconds % 3600) / 60

        { days: days, hours: hours, minutes: minutes }
      end
    end
  end
end
