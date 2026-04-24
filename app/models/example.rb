class Example < ApplicationRecord
  belongs_to :word

  validates :sentence, presence: true, length: { maximum: 1000 }
  validates :translation, presence: true, length: { maximum: 1000 }
  validates :display_order, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
