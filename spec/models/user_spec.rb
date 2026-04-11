require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:wordbooks).dependent(:destroy) }
    it { is_expected.to have_one(:setting).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_uniqueness_of(:email).allow_nil }

    context 'when provider is google' do
      subject { build(:user, provider: 'google') }

      it { is_expected.to validate_presence_of(:provider_uid) }
      it { is_expected.to validate_uniqueness_of(:provider_uid).scoped_to(:provider) }
    end

    context 'when provider is guest' do
      it 'does not require provider_uid' do
        user = build(:user, :guest, provider_uid: nil)
        expect(user).to be_valid
      end
    end
  end

  describe 'enum' do
    subject(:user) { build(:user) }

    it {
      expect(user).to define_enum_for(:provider).with_values(google: 'google',
                                                             guest: 'guest').backed_by_column_of_type(:string)
    }
  end

  describe 'guest user validations' do
    context 'when provider is guest' do
      it 'requires guest_expires_at' do
        user = build(:user, :guest, guest_expires_at: nil)
        expect(user).not_to be_valid
        expect(user.errors[:guest_expires_at]).to include("can't be blank")
      end

      it 'is valid with guest_expires_at set' do
        user = build(:user, :guest)
        expect(user).to be_valid
      end
    end

    context 'when provider is google' do
      it 'does not require guest_expires_at' do
        user = build(:user, guest_expires_at: nil)
        expect(user).to be_valid
      end
    end
  end

  describe 'factory' do
    it 'creates a valid google user' do
      expect(build(:user)).to be_valid
    end

    it 'creates a valid guest user' do
      expect(build(:user, :guest)).to be_valid
    end
  end

  describe 'User::MigrationResult' do
    describe '.success' do
      it 'returns a successful result with the user' do
        user = build(:user)
        result = User::MigrationResult.success(user)

        expect(result).to be_success
        expect(result.user).to eq(user)
        expect(result.error).to be_nil
      end
    end

    describe '.failure' do
      it 'returns a failed result with the error message' do
        result = User::MigrationResult.failure('Something went wrong')

        expect(result).not_to be_success
        expect(result.user).to be_nil
        expect(result.error).to eq('Something went wrong')
      end
    end
  end

  describe '.find_by_token' do
    let(:guest_user) { create(:user, :guest) }

    context 'when token is valid and belongs to a guest user' do
      it 'returns the guest user' do
        token = JsonWebToken.encode(guest_user.id, expires_at: guest_user.guest_expires_at)

        expect(described_class.find_by_token(token)).to eq(guest_user)
      end
    end

    context 'when token is invalid' do
      it 'returns nil' do
        expect(described_class.find_by_token('invalid_token')).to be_nil
      end
    end

    context 'when token belongs to a Google user' do
      it 'returns the Google user' do
        google_user = create(:user, provider: 'google')
        token = JsonWebToken.encode(google_user.id)

        expect(described_class.find_by_token(token)).to eq(google_user)
      end
    end
  end

  describe '#migrate_to_google' do
    let(:google_payload) do
      {
        'sub' => 'google_uid_123',
        'email' => 'test@example.com',
        'name' => 'Test User',
        'picture' => 'https://example.com/avatar.jpg'
      }
    end

    context 'when called on a non-guest user' do
      it 'returns a failure result' do
        google_user = create(:user, provider: 'google')
        result = google_user.migrate_to_google(google_payload)

        expect(result).not_to be_success
        expect(result.error).to eq('User is not a guest')
      end
    end

    context 'when Google account does not exist (in-place conversion)' do
      let(:guest_user) { create(:user, :guest) }
      let!(:wordbook) { create(:wordbook, user: guest_user, title: 'Guest Wordbook') }
      let!(:setting) { create(:setting, user: guest_user) }

      it 'converts guest user to Google user' do
        result = guest_user.migrate_to_google(google_payload)

        expect(result).to be_success
        expect(result.user).to eq(guest_user)

        guest_user.reload
        expect(guest_user.provider).to eq('google')
        expect(guest_user.provider_uid).to eq('google_uid_123')
        expect(guest_user.email).to eq('test@example.com')
        expect(guest_user.name).to eq('Test User')
        expect(guest_user.avatar_url).to eq('https://example.com/avatar.jpg')
        expect(guest_user.guest_expires_at).to be_nil
      end

      it 'preserves associated data' do
        guest_user.migrate_to_google(google_payload)

        guest_user.reload
        expect(guest_user.wordbooks.count).to eq(1)
        expect(guest_user.setting).to be_present
      end

      it 'does not change user count' do
        expect { guest_user.migrate_to_google(google_payload) }.not_to change(described_class, :count)
      end
    end

    context 'when Google account already exists (merge)' do
      let(:guest_user) { create(:user, :guest) }
      let!(:google_user) do
        create(:user, provider: 'google', provider_uid: 'google_uid_123', email: 'test@example.com')
      end
      let!(:guest_wordbook) { create(:wordbook, user: guest_user, title: 'Guest Wordbook') }
      let!(:guest_setting) { create(:setting, user: guest_user) }

      it 'returns the Google user as the result' do
        result = guest_user.migrate_to_google(google_payload)

        expect(result).to be_success
        expect(result.user).to eq(google_user)
      end

      it 'transfers wordbooks to the Google user' do
        guest_user.migrate_to_google(google_payload)

        expect(google_user.wordbooks.count).to eq(1)
        expect(google_user.wordbooks.first.title).to eq('Guest Wordbook')
      end

      it 'transfers setting when Google user has no setting' do
        guest_user.migrate_to_google(google_payload)

        expect(google_user.reload.setting).to be_present
      end

      it 'keeps Google user setting when both have settings' do
        google_setting = create(:setting, user: google_user, hard_interval: 2.days)

        guest_user.migrate_to_google(google_payload)

        expect(google_user.reload.setting.id).to eq(google_setting.id)
      end

      it 'destroys the guest user' do
        expect { guest_user.migrate_to_google(google_payload) }.to change(described_class, :count).by(-1)
        expect { guest_user.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#effective_setting' do
    let(:user) { create(:user) }

    context 'when user has a setting record' do
      let!(:setting) { create(:setting, user: user) }

      it 'returns the user setting' do
        expect(user.effective_setting).to eq(setting)
      end
    end

    context 'when user has no setting record' do
      it 'returns the default setting' do
        expect(user.effective_setting).to eq(Setting.default)
      end
    end
  end
end
