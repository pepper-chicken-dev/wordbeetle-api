class SettingResource
  include Alba::Resource

  attribute :hard_interval do |setting|
    duration_to_hash(setting.hard_interval)
  end

  attribute :uncertain_interval do |setting|
    duration_to_hash(setting.uncertain_interval)
  end

  attribute :easy_interval do |setting|
    duration_to_hash(setting.easy_interval)
  end

  private

  def duration_to_hash(duration)
    return nil if duration.blank?

    { days: 0, hours: 0, minutes: 0 }.merge(duration.parts.slice(:days, :hours, :minutes))
  end
end
