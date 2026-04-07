class Setting < ApplicationRecord
  DefaultSetting = Struct.new(:hard_interval, :uncertain_interval, :easy_interval) do
    def as_json(*)
      {}
    end
  end

  def self.default
    DefaultSetting.new(1.day, 3.days, 7.days)
  end

  belongs_to :user

  validates :hard_interval, :uncertain_interval, :easy_interval, presence: true
  validate :intervals_must_be_positive

  private

  def intervals_must_be_positive
    %i[hard_interval uncertain_interval easy_interval].each do |attr|
      value = send(attr)
      next if value.blank?

      unless value.is_a?(ActiveSupport::Duration) && value.to_i.positive?
        errors.add(attr,
                   'must be a positive interval')
      end
    end
  end
end
