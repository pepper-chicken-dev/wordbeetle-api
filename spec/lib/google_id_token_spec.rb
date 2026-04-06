require 'rails_helper'

RSpec.describe GoogleIdToken do
  describe '.decode' do
    let(:payload) do
      {
        'sub' => 'google_uid_123',
        'email' => 'test@example.com',
        'name' => 'Test User',
        'picture' => 'https://example.com/avatar.jpg'
      }
    end

    context 'when token is valid' do
      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_return(payload)
      end

      it 'returns the decoded payload' do
        result = described_class.decode('valid_token')

        expect(result).to eq(payload)
      end

      it 'passes GOOGLE_CLIENT_ID as audience' do
        allow(ENV).to receive(:fetch).with('GOOGLE_CLIENT_ID', nil).and_return('test_client_id')

        described_class.decode('valid_token')

        expect(Google::Auth::IDTokens).to have_received(:verify_oidc).with('valid_token', aud: 'test_client_id')
      end
    end

    context 'when token verification fails' do
      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_raise(
          Google::Auth::IDTokens::VerificationError.new('Token expired')
        )
      end

      it 'raises GoogleIdToken::VerificationError' do
        expect do
          described_class.decode('invalid_token')
        end.to raise_error(GoogleIdToken::VerificationError, 'Token expired')
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)

        begin
          described_class.decode('invalid_token')
        rescue GoogleIdToken::VerificationError
          # expected
        end

        expect(Rails.logger).to have_received(:error).with('Google ID token verification failed: Token expired')
      end
    end

    context 'when an unexpected error occurs' do
      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_raise(
          RuntimeError.new('Network error')
        )
      end

      it 'does not rescue the error' do
        expect do
          described_class.decode('valid_token')
        end.to raise_error(RuntimeError, 'Network error')
      end
    end
  end
end
