class AddCheckConstraintsToSettingsIntervals < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :settings,
                         "hard_interval > '0' AND uncertain_interval > '0' AND easy_interval > '0'",
                         name: 'check_settings_intervals_positive'

    add_check_constraint :settings,
                         'hard_interval < uncertain_interval AND uncertain_interval < easy_interval',
                         name: 'check_settings_intervals_ascending_order'
  end
end
