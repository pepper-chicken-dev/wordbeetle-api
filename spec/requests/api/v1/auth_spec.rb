require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  describe "POST /api/v1/auth/guest" do
    it "creates a guest user and returns 201 with user and token" do
      expect {
        post "/api/v1/auth/guest"
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)

      body = response.parsed_body
      expect(body["user"]["provider"]).to eq("guest")
      expect(body["token"]).to be_present
    end

    it "sets guest_expires_at to approximately 7 days from now" do
      post "/api/v1/auth/guest"

      user = User.last
      expect(user.guest_expires_at).to be_within(1.second).of(7.days.from_now)
    end

    it "returns a token that can be verified" do
      post "/api/v1/auth/guest"

      body = response.parsed_body
      token = body["token"]
      provider_uid = body["user"]["provider_uid"]

      verifier = ActiveSupport::MessageVerifier.new(
        Rails.application.key_generator.generate_key("guest_auth")
      )
      expect(verifier.verify(token, purpose: :guest_auth)).to eq(provider_uid)
    end
  end

  describe "POST /api/v1/auth/google" do
    let(:google_payload) do
      {
        "sub" => "google_uid_123",
        "email" => "test@example.com",
        "name" => "Test User",
        "picture" => "https://example.com/avatar.jpg"
      }
    end

    context "when Authorization header is missing" do
      it "returns bad_request" do
        post "/api/v1/auth/google"

        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["error"]).to eq("Authorization header missing")
      end
    end

    context "when token is invalid" do
      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_raise(
          Google::Auth::IDTokens::VerificationError.new("Invalid token")
        )
      end

      it "returns unauthorized" do
        post "/api/v1/auth/google", headers: { "Authorization" => "Bearer invalid_token" }

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["error"]).to eq("Invalid ID token")
      end
    end

    context "when token is valid and user is new" do
      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_return(google_payload)
      end

      it "creates a new user and returns ok" do
        expect {
          post "/api/v1/auth/google", headers: { "Authorization" => "Bearer valid_token" }
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["user"]["email"]).to eq("test@example.com")
      end
    end

    context "when token is valid and user already exists" do
      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_return(google_payload)
        create(:user, provider: "google", provider_uid: "google_uid_123", email: "test@example.com")
      end

      it "returns existing user without creating a new one" do
        expect {
          post "/api/v1/auth/google", headers: { "Authorization" => "Bearer valid_token" }
        }.not_to change(User, :count)

        expect(response).to have_http_status(:ok)
      end
    end

    context "when email is already registered with a different provider" do
      before do
        allow(Google::Auth::IDTokens).to receive(:verify_oidc).and_return(google_payload)
        create(:user, :guest, provider_uid: "guest_uid_999", email: "test@example.com")
      end

      it "returns conflict" do
        post "/api/v1/auth/google", headers: { "Authorization" => "Bearer valid_token" }

        expect(response).to have_http_status(:conflict)
        expect(response.parsed_body["error"]).to include("already registered")
      end
    end
  end
end
