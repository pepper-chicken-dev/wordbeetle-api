module Reviewable
  extend ActiveSupport::Concern

  included do
    before_update :recalculate_next_review_at, if: :status_assigned?
    after_save :reset_status_assigned_flag

    prepend(Module.new do
      def status=(value)
        @status_assigned = true
        super
      end
    end)
  end

  private

  def status_assigned?
    @status_assigned == true
  end

  def reset_status_assigned_flag
    @status_assigned = false
  end

  def recalculate_next_review_at
    setting = wordbook.user.effective_setting

    if status.to_sym == :not_studied
      self.next_review_at = nil
    elsif !status_changed? || next_review_at.nil? || status_was.to_sym == :not_studied || next_review_at <= Time.current
      self.next_review_at = Time.current + interval_for(status, setting)
    else
      adjustment = interval_for(status, setting) - interval_for(status_was, setting)
      self.next_review_at = next_review_at + adjustment
    end
  end

  def interval_for(status_key, setting)
    case status_key.to_sym
    when :hard      then setting.hard_interval
    when :uncertain then setting.uncertain_interval
    when :easy      then setting.easy_interval
    end
  end
end
