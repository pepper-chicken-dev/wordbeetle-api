require 'rails_helper'

RSpec.describe 'Api::V1::Auth', type: :request do
  describe 'POST /api/v1/auth/guest' do
    it 'creates a guest user and returns 201 with user and JWT token' do
      expect do
        post '/api/v1/auth/guest'
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)

      body = response.parsed_body
      expect(body['user']).to have_key('guest_expires_at')
      expect(body['user'].keys).to contain_exactly('guest_expires_at')
      expect(body['token']).to be_present
    end

    it 'sets guest_expires_at to approximately 7 days from now' do
      post '/api/v1/auth/guest'

      user = User.last
      expect(user.guest_expires_at).to be_within(1.second).of(7.days.from_now)
    end

    it 'returns a JWT token containing the user_id' do
      post '/api/v1/auth/guest'

      body = response.parsed_body
      token = body['token']
      user = User.last

      decoded = JsonWebToken.decode(token)
      expect(decoded['sub']).to eq(user.id)
    end

    it 'returns a JWT token that expires at guest_expires_at' do
      post '/api/v1/auth/guest'

      body = response.parsed_body
      token = body['token']
      user = User.last

      decoded = JsonWebToken.decode(token)
      expect(decoded['exp']).to eq(user.guest_expires_at.to_i)
    end
  end

  describe 'POST /api/v1/auth/google' do
    let(:google_payload) do
      {
        'sub' => 'google_uid_123',
        'email' => 'test@example.com',
        'name' => 'Test User',
        'picture' => 'https://example.com/avatar.jpg'
      }
    end

    context 'when Authorization header is missing' do
      it 'returns bad_request' do
        post '/api/v1/auth/google'

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body['error']).to eq('Authorization header missing')
      end
    end

    context 'when token is invalid' do
      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_raise(
          Google::Auth::IDTokens::VerificationError.new('Invalid token')
        )
      end

      it 'returns unauthorized' do
        post '/api/v1/auth/google', headers: { 'Authorization' => 'Bearer invalid_token' }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body['error']).to eq('Invalid ID token')
      end
    end

    context 'when an unexpected error occurs during token verification' do
      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_raise(
          RuntimeError.new('Unexpected network error')
        )
      end

      it 'raises the error instead of returning unauthorized' do
        expect do
          post '/api/v1/auth/google', headers: { 'Authorization' => 'Bearer valid_token' }
        end.to raise_error(RuntimeError, 'Unexpected network error')
      end
    end

    context 'when token is valid and user is new' do
      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_return(google_payload)
      end

      it 'creates a new user and returns ok with JWT token' do
        expect do
          post '/api/v1/auth/google', headers: { 'Authorization' => 'Bearer valid_token' }
        end.to change(User, :count).by(1)

        expect(response).to have_http_status(:ok)

        body = response.parsed_body
        user_json = body['user']
        expect(user_json['email']).to eq('test@example.com')
        expect(user_json['name']).to eq('Test User')
        expect(user_json['avatar_url']).to eq('https://example.com/avatar.jpg')
        expect(user_json.keys).to match_array(%w[email name avatar_url])

        expect(body['token']).to be_present
        decoded = JsonWebToken.decode(body['token'])
        expect(decoded['sub']).to eq(User.last.id)
      end
    end

    context 'when token is valid and user already exists' do
      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_return(google_payload)
        create(:user, provider: 'google', provider_uid: 'google_uid_123', email: 'test@example.com')
      end

      it 'returns existing user without creating a new one' do
        expect do
          post '/api/v1/auth/google', headers: { 'Authorization' => 'Bearer valid_token' }
        end.not_to change(User, :count)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['token']).to be_present
      end
    end

    context 'when email is already registered with a different provider' do
      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_return(google_payload)
        create(:user, :guest, email: 'test@example.com')
      end

      it 'returns conflict' do
        post '/api/v1/auth/google', headers: { 'Authorization' => 'Bearer valid_token' }

        expect(response).to have_http_status(:conflict)
        expect(response.parsed_body['error']).to include('already registered')
      end
    end

    context 'with guest_token (guest migration)' do
      let(:guest_user) { create(:user, :guest) }
      let(:guest_token) do
        JsonWebToken.encode(guest_user.id, expires_at: guest_user.guest_expires_at)
      end

      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_return(google_payload)
      end

      context 'when Google account does not exist (in-place conversion)' do
        let!(:wordbook) { create(:wordbook, user: guest_user, title: 'Guest Wordbook') }
        let!(:word) { create(:word, wordbook: wordbook, spelling: 'apple') }
        let!(:meaning) { create(:meaning, word: word, content: 'りんご') }
        let!(:example) { create(:example, word: word, sentence: 'I like apples.', translation: 'りんごが好きです。') }
        let!(:setting) { create(:setting, user: guest_user) }

        it 'converts guest user to Google user and returns ok' do
          expect do
            post '/api/v1/auth/google',
                 params: { guest_token: guest_token },
                 headers: { 'Authorization' => 'Bearer valid_token' }
          end.not_to change(User, :count)

          expect(response).to have_http_status(:ok)

          body = response.parsed_body
          expect(body['user']['email']).to eq('test@example.com')
          expect(body['user']['name']).to eq('Test User')
          expect(body['user']['avatar_url']).to eq('https://example.com/avatar.jpg')
          expect(body['token']).to be_present
        end

        it 'updates guest user attributes to Google user' do
          post '/api/v1/auth/google',
               params: { guest_token: guest_token },
               headers: { 'Authorization' => 'Bearer valid_token' }

          guest_user.reload
          expect(guest_user.provider).to eq('google')
          expect(guest_user.provider_uid).to eq('google_uid_123')
          expect(guest_user.email).to eq('test@example.com')
          expect(guest_user.guest_expires_at).to be_nil
        end

        it 'preserves all guest data (wordbooks, words, meanings, examples, settings)' do
          post '/api/v1/auth/google',
               params: { guest_token: guest_token },
               headers: { 'Authorization' => 'Bearer valid_token' }

          guest_user.reload
          expect(guest_user.wordbooks.count).to eq(1)
          expect(guest_user.wordbooks.first.title).to eq('Guest Wordbook')
          expect(guest_user.wordbooks.first.words.count).to eq(1)
          expect(guest_user.wordbooks.first.words.first.meanings.count).to eq(1)
          expect(guest_user.wordbooks.first.words.first.examples.count).to eq(1)
          expect(guest_user.setting).to be_present
        end

        it 'returns a JWT token for the converted user' do
          post '/api/v1/auth/google',
               params: { guest_token: guest_token },
               headers: { 'Authorization' => 'Bearer valid_token' }

          token = response.parsed_body['token']
          decoded = JsonWebToken.decode(token)
          expect(decoded['sub']).to eq(guest_user.id)
        end
      end

      context 'when Google account already exists (merge)' do
        let!(:google_user) do
          create(:user, provider: 'google', provider_uid: 'google_uid_123', email: 'test@example.com')
        end
        let!(:guest_wordbook) { create(:wordbook, user: guest_user, title: 'Guest Wordbook') }
        let!(:guest_word) { create(:word, wordbook: guest_wordbook, spelling: 'banana') }
        let!(:guest_meaning) { create(:meaning, word: guest_word, content: 'バナナ') }
        let!(:guest_setting) { create(:setting, user: guest_user) }

        it 'merges guest data into existing Google user and deletes guest' do
          expect do
            post '/api/v1/auth/google',
                 params: { guest_token: guest_token },
                 headers: { 'Authorization' => 'Bearer valid_token' }
          end.to change(User, :count).by(-1)

          expect(response).to have_http_status(:ok)
          expect { guest_user.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'transfers wordbooks to the Google user' do
          post '/api/v1/auth/google',
               params: { guest_token: guest_token },
               headers: { 'Authorization' => 'Bearer valid_token' }

          expect(google_user.wordbooks.count).to eq(1)
          expect(google_user.wordbooks.first.title).to eq('Guest Wordbook')
          expect(google_user.wordbooks.first.words.first.meanings.count).to eq(1)
        end

        it 'transfers setting when Google user has no setting' do
          post '/api/v1/auth/google',
               params: { guest_token: guest_token },
               headers: { 'Authorization' => 'Bearer valid_token' }

          expect(google_user.reload.setting).to be_present
        end

        it 'keeps Google user setting when both have settings' do
          google_setting = create(:setting, user: google_user, hard_interval: 2.days)

          post '/api/v1/auth/google',
               params: { guest_token: guest_token },
               headers: { 'Authorization' => 'Bearer valid_token' }

          google_user.reload
          expect(google_user.setting.id).to eq(google_setting.id)
        end

        it 'returns a JWT token for the Google user' do
          post '/api/v1/auth/google',
               params: { guest_token: guest_token },
               headers: { 'Authorization' => 'Bearer valid_token' }

          token = response.parsed_body['token']
          decoded = JsonWebToken.decode(token)
          expect(decoded['sub']).to eq(google_user.id)
        end
      end

      context 'when guest_token is invalid' do
        it 'returns unauthorized' do
          post '/api/v1/auth/google',
               params: { guest_token: 'invalid_token' },
               headers: { 'Authorization' => 'Bearer valid_token' }

          expect(response).to have_http_status(:unauthorized)
          expect(response.parsed_body['error']).to eq('Invalid guest token')
        end
      end

      context 'when guest_token belongs to a Google user' do
        let(:google_user) { create(:user, provider: 'google', provider_uid: 'other_uid') }
        let(:non_guest_token) do
          JsonWebToken.encode(google_user.id)
        end

        it 'returns unauthorized' do
          post '/api/v1/auth/google',
               params: { guest_token: non_guest_token },
               headers: { 'Authorization' => 'Bearer valid_token' }

          expect(response).to have_http_status(:unauthorized)
          expect(response.parsed_body['error']).to eq('Invalid guest token')
        end
      end
    end
  end
end
