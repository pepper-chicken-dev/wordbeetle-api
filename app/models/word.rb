class Word < ApplicationRecord
  belongs_to :wordbook
  has_many :meanings, dependent: :destroy
  has_many :examples, dependent: :destroy

  validates :spelling, presence: true
  validates :status, presence: true

  enum :status, { not_studied: "not_studied", hard: "hard", uncertain: "uncertain", easy: "easy" }
end
