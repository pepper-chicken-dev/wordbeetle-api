class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :google_id, presence: true, uniqueness: true
end
