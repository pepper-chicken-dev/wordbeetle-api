class Example < ApplicationRecord
  belongs_to :word

  validates :sentence, presence: true
  validates :translation, presence: true
  validates :display_order, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
