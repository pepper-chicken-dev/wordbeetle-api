require 'rails_helper'

RSpec.describe CleanupExpiredGuestsJob, type: :job do
  describe '#perform' do
    context 'when expired guest users exist' do
      it 'deletes expired guest users' do
        expired_guest = create(:user, :guest, guest_expires_at: 1.day.ago)

        expect { described_class.perform_now }.to change(User, :count).by(-1)
        expect(User.exists?(expired_guest.id)).to be false
      end

      it 'logs the number of deleted users' do
        create(:user, :guest, guest_expires_at: 1.day.ago)
        create(:user, :guest, guest_expires_at: 2.days.ago)

        allow(Rails.logger).to receive(:info)
        described_class.perform_now
        expect(Rails.logger).to have_received(:info).with('CleanupExpiredGuestsJob: Deleted 2 expired guest user(s)')
      end
    end

    context 'when active guest users exist' do
      it 'does not delete active guest users' do
        active_guest = create(:user, :guest, guest_expires_at: 1.day.from_now)

        expect { described_class.perform_now }.not_to change(User, :count)
        expect(User.exists?(active_guest.id)).to be true
      end
    end

    context 'when Google users exist' do
      it 'does not delete Google users' do
        google_user = create(:user)

        expect { described_class.perform_now }.not_to change(User, :count)
        expect(User.exists?(google_user.id)).to be true
      end
    end

    context 'when expired guest users have associated data' do
      it 'cascade-deletes associated data (Wordbook, Word, Meaning, Example, Setting)' do
        expired_guest = create(:user, :guest, guest_expires_at: 1.day.ago)
        wordbook = create(:wordbook, user: expired_guest)
        word = create(:word, wordbook: wordbook)
        create(:meaning, word: word)
        create(:example, word: word)
        create(:setting, user: expired_guest)

        described_class.perform_now

        expect(User.exists?(expired_guest.id)).to be false
        expect(Wordbook.exists?(wordbook.id)).to be false
        expect(Word.exists?(word.id)).to be false
        expect(Meaning.where(word_id: word.id)).to be_empty
        expect(Example.where(word_id: word.id)).to be_empty
      end
    end
  end
end
