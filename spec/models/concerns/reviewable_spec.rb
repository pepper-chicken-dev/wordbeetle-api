require 'rails_helper'

RSpec.describe Reviewable, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:wordbook) { create(:wordbook, user: user) }

  describe 'before_update callback' do
    context 'when status is unchanged' do
      let(:word) { create(:word, wordbook: wordbook, status: 'easy', next_review_at: 5.days.from_now) }

      it 'does not recalculate next_review_at' do
        original = word.next_review_at
        word.update!(spelling: 'changed')
        expect(word.next_review_at).to eq(original)
      end
    end

    context 'when changing to not_studied' do
      let(:word) { create(:word, wordbook: wordbook, status: 'easy', next_review_at: 5.days.from_now) }

      it 'sets next_review_at to nil' do
        word.update!(status: 'not_studied')
        expect(word.next_review_at).to be_nil
      end
    end

    context 'when changing from not_studied to hard (next_review_at is nil)' do
      let(:word) { create(:word, wordbook: wordbook, status: 'not_studied', next_review_at: nil) }

      it 'sets next_review_at to now + hard_interval' do
        freeze_time do
          word.update!(status: 'hard')
          expect(word.next_review_at).to eq(1.day.from_now)
        end
      end
    end

    context 'when changing from not_studied to easy (next_review_at is nil)' do
      let(:word) { create(:word, wordbook: wordbook, status: 'not_studied', next_review_at: nil) }

      it 'sets next_review_at to now + easy_interval' do
        freeze_time do
          word.update!(status: 'easy')
          expect(word.next_review_at).to eq(7.days.from_now)
        end
      end
    end

    context 'when next_review_at is in the past (immediately reviewable)' do
      let(:past_date) { 2.days.ago }
      let(:word) { create(:word, wordbook: wordbook, status: 'easy', next_review_at: past_date) }

      it 'keeps next_review_at unchanged' do
        db_past_date = word.reload.next_review_at
        word.update!(status: 'hard')
        expect(word.reload.next_review_at).to eq(db_past_date)
      end
    end

    context 'when changing from easy to hard with future next_review_at' do
      let(:future_date) { 10.days.from_now }
      let(:word) { create(:word, wordbook: wordbook, status: 'easy', next_review_at: future_date) }

      it 'adjusts next_review_at earlier by the interval difference' do
        freeze_time do
          word.update!(status: 'hard')
          # easy_interval(7d) - hard_interval(1d) = 6d earlier
          expect(word.next_review_at).to eq(future_date - 6.days)
        end
      end
    end

    context 'when changing from hard to easy with future next_review_at' do
      let(:future_date) { 5.days.from_now }
      let(:word) { create(:word, wordbook: wordbook, status: 'hard', next_review_at: future_date) }

      it 'adjusts next_review_at later by the interval difference' do
        freeze_time do
          word.update!(status: 'easy')
          # hard_interval(1d) - easy_interval(7d) = -6d (later)
          expect(word.next_review_at).to eq(future_date + 6.days)
        end
      end
    end

    context 'with custom user settings' do
      let!(:setting) do
        create(:setting, user: user, hard_interval: 2.days, uncertain_interval: 4.days, easy_interval: 10.days)
      end
      let(:future_date) { 15.days.from_now }
      let(:word) { create(:word, wordbook: wordbook, status: 'easy', next_review_at: future_date) }

      it 'uses custom intervals for recalculation' do
        freeze_time do
          word.update!(status: 'hard')
          # easy_interval(10d) - hard_interval(2d) = 8d earlier
          expect(word.next_review_at).to eq(future_date - 8.days)
        end
      end
    end
  end
end
