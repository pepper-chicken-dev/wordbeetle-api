class Meaning < ApplicationRecord
  belongs_to :word

  validates :definition, presence: true, length: { maximum: 1000 }
  validates :display_order, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
