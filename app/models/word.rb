class Word < ApplicationRecord
  include Reviewable

  belongs_to :wordbook
  has_many :meanings, dependent: :destroy
  has_many :examples, through: :meanings
  has_one :first_meaning, -> { order(:display_order) }, class_name: 'Meaning', dependent: nil, inverse_of: false

  accepts_nested_attributes_for :meanings

  validates :spelling, presence: true, length: { maximum: 255 }
  validates :status, presence: true

  enum :status, { not_studied: 'not_studied', hard: 'hard', uncertain: 'uncertain', easy: 'easy' }

  scope :reviewable, -> { where('next_review_at IS NULL OR next_review_at <= ?', Time.current) }
end
