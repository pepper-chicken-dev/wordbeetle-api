require "rails_helper"

RSpec.describe "Api::V1::Settings", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe "GET /api/v1/settings" do
    it "returns current user's settings" do
      create(:setting, user: user)

      get "/api/v1/settings", headers: headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body.size).to eq(1)
      expect(body.first["hard_interval"]).to include("days", "hours", "minutes")
    end

    it "does not return other users' settings" do
      create(:setting, user: user)
      create(:setting) # another user's setting

      get "/api/v1/settings", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(1)
    end

    it "returns 401 without authentication" do
      get "/api/v1/settings"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/settings/:id" do
    it "returns the current user's setting" do
      setting = create(:setting, user: user)

      get "/api/v1/settings/#{setting.id}", headers: headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["hard_interval"]).to eq({ "days" => 1, "hours" => 0, "minutes" => 0 })
      expect(body["uncertain_interval"]).to eq({ "days" => 3, "hours" => 0, "minutes" => 0 })
      expect(body["easy_interval"]).to eq({ "days" => 7, "hours" => 0, "minutes" => 0 })
    end

    it "returns not_found when user has no setting" do
      get "/api/v1/settings/999999", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/settings" do
    context "with valid params" do
      it "creates a setting for the current user" do
        params = {
          setting: {
            hard_interval: { days: 1, hours: 0, minutes: 0 },
            uncertain_interval: { days: 3, hours: 0, minutes: 0 },
            easy_interval: { days: 7, hours: 0, minutes: 0 }
          }
        }

        expect {
          post "/api/v1/settings", params: params, headers: headers
        }.to change(Setting, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(Setting.last.user_id).to eq(user.id)
      end
    end

    context "with missing intervals" do
      it "returns unprocessable_entity" do
        params = {
          setting: {
            hard_interval: { days: 1, hours: 0, minutes: 0 }
          }
        }

        post "/api/v1/settings", params: params, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /api/v1/settings/:id" do
    let!(:setting) { create(:setting, user: user) }

    it "updates the setting" do
      patch "/api/v1/settings/#{setting.id}", params: {
        setting: {
          hard_interval: { days: 2, hours: 0, minutes: 0 }
        }
      }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["hard_interval"]).to eq({ "days" => 2, "hours" => 0, "minutes" => 0 })
    end
  end

  describe "DELETE /api/v1/settings/:id" do
    it "deletes the setting" do
      setting = create(:setting, user: user)

      expect {
        delete "/api/v1/settings/#{setting.id}", headers: headers
      }.to change(Setting, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
