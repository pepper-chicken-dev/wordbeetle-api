class User < ApplicationRecord
  has_many :wordbooks, dependent: :destroy
  has_one :setting, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :provider, presence: true
  validates :provider_uid, presence: true, uniqueness: { scope: :provider }
end
