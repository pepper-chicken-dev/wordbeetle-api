module Api
  module V1
    class SettingsController < ApplicationController
      before_action :set_setting, only: %i[update destroy]

      def show
        render json: setting_response(current_user.effective_setting)
      end

      def create
        setting = current_user.build_setting(build_setting_params)

        if setting.save
          render json: setting_response(setting), status: :created
        else
          render json: { errors: setting.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        if @setting.update(build_setting_params)
          render json: setting_response(@setting)
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

      def setting_response(setting)
        except_keys = %i[hard_interval uncertain_interval easy_interval]
        except_keys += %i[id user_id created_at updated_at] unless setting.persisted?
        setting.as_json(except: except_keys).merge(
          hard_interval: duration_to_hash(setting.hard_interval),
          uncertain_interval: duration_to_hash(setting.uncertain_interval),
          easy_interval: duration_to_hash(setting.easy_interval)
        )
      end

      def duration_to_hash(duration)
        return nil if duration.blank?

        { days: 0, hours: 0, minutes: 0 }.merge(duration.parts.slice(:days, :hours, :minutes))
      end
    end
  end
end
