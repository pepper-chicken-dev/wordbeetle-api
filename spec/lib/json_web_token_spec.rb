require 'rails_helper'

RSpec.describe JsonWebToken do
  let(:user_id) { 1 }

  describe '.encode' do
    it 'returns a valid JWT token string' do
      token = described_class.encode(user_id)

      expect(token).to be_a(String)
      expect(token.split('.').length).to eq(3)
    end

    it 'encodes the user_id as the sub claim' do
      token = described_class.encode(user_id)
      payload = described_class.decode(token)

      expect(payload['sub']).to eq(user_id)
    end

    it 'sets exp to 30 days from now by default' do
      token = described_class.encode(user_id)
      payload = described_class.decode(token)

      expect(payload['exp']).to be_within(2).of(30.days.from_now.to_i)
    end

    it 'allows custom expires_at' do
      expires_at = 7.days.from_now
      token = described_class.encode(user_id, expires_at: expires_at)
      payload = described_class.decode(token)

      expect(payload['exp']).to eq(expires_at.to_i)
    end

    it 'includes iat claim' do
      token = described_class.encode(user_id)
      payload = described_class.decode(token)

      expect(payload['iat']).to be_within(2).of(Time.current.to_i)
    end
  end

  describe '.decode' do
    it 'decodes a valid token and returns the payload' do
      token = described_class.encode(user_id)
      payload = described_class.decode(token)

      expect(payload['sub']).to eq(user_id)
      expect(payload['exp']).to be_present
      expect(payload['iat']).to be_present
    end

    it 'returns nil for an expired token' do
      token = described_class.encode(user_id, expires_at: 1.day.ago)

      expect(described_class.decode(token)).to be_nil
    end

    it 'returns nil for an invalid token' do
      expect(described_class.decode('invalid.token.here')).to be_nil
    end

    it 'returns nil for a token signed with wrong key' do
      payload = { sub: user_id, exp: 30.days.from_now.to_i, iat: Time.current.to_i }
      token = JWT.encode(payload, 'wrong_secret', 'HS256')

      expect(described_class.decode(token)).to be_nil
    end
  end
end
