class Meaning < ApplicationRecord
  belongs_to :word
  has_many :examples, dependent: :destroy

  accepts_nested_attributes_for :examples

  validates :definition, presence: true, length: { maximum: 1000 }
  validates :display_order, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
