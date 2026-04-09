class CleanupExpiredGuestsJob < ApplicationJob
  queue_as :default

  def perform
    expired_guests = User.where(provider: 'guest').where(guest_expires_at: ...Time.current)
    count = expired_guests.count
    expired_guests.find_each(&:destroy)
    Rails.logger.info "CleanupExpiredGuestsJob: Deleted #{count} expired guest user(s)"
  end
end
