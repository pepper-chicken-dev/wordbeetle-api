class Wordbook < ApplicationRecord
  belongs_to :user
  has_many :words, dependent: :destroy

  validates :title, presence: true

  API_FIELDS = %i[id title created_at].freeze
end
