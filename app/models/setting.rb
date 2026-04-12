class Setting < ApplicationRecord
  def self.default
    Setting.new(
      hard_interval: 1.day,
      uncertain_interval: 3.days,
      easy_interval: 7.days
    ).freeze
  end

  belongs_to :user

  validates :hard_interval, :uncertain_interval, :easy_interval, presence: true
  validate :intervals_must_be_positive
  validate :intervals_must_be_in_ascending_order

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

  def intervals_must_be_in_ascending_order
    intervals = [hard_interval, uncertain_interval, easy_interval]

    return if intervals.any?(&:blank?)
    return if intervals.any? { |v| !(v.is_a?(ActiveSupport::Duration) && v.to_i.positive?) }
    return if hard_interval < uncertain_interval && uncertain_interval < easy_interval

    errors.add(:base, 'intervals must be in ascending order: hard < uncertain < easy')
  end
end
