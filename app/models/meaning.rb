class Meaning < ApplicationRecord
  belongs_to :word

  validates :definition, presence: true
  validates :display_order, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
