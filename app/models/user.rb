class User < ApplicationRecord
  has_many :wordbooks, dependent: :destroy
  has_one :setting, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :google_id, presence: true, uniqueness: true
end
