class Setting < ApplicationRecord
  belongs_to :user

  validates :hard_interval_days, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :uncertain_interval_days, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :easy_interval_days, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
