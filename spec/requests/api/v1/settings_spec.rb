require "rails_helper"

RSpec.describe "Api::V1::Settings", type: :request do
  let(:user) { create(:user) }

  describe "GET /api/v1/settings" do
    it "returns all settings with interval hashes" do
      create(:setting, user: user)

      get "/api/v1/settings"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body.size).to eq(1)
      expect(body.first["hard_interval"]).to include("days", "hours", "minutes")
    end
  end

  describe "GET /api/v1/settings/:id" do
    it "returns the setting with interval hashes" do
      setting = create(:setting, user: user)

      get "/api/v1/settings/#{setting.id}"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["hard_interval"]).to eq({ "days" => 1, "hours" => 0, "minutes" => 0 })
      expect(body["uncertain_interval"]).to eq({ "days" => 3, "hours" => 0, "minutes" => 0 })
      expect(body["easy_interval"]).to eq({ "days" => 7, "hours" => 0, "minutes" => 0 })
    end
  end

  describe "POST /api/v1/settings" do
    context "with valid params" do
      it "creates a setting" do
        params = {
          setting: {
            user_id: user.id,
            hard_interval: { days: 1, hours: 0, minutes: 0 },
            uncertain_interval: { days: 3, hours: 0, minutes: 0 },
            easy_interval: { days: 7, hours: 0, minutes: 0 }
          }
        }

        expect {
          post "/api/v1/settings", params: params
        }.to change(Setting, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context "with missing intervals" do
      it "returns unprocessable_entity" do
        params = {
          setting: {
            user_id: user.id,
            hard_interval: { days: 1, hours: 0, minutes: 0 }
          }
        }

        post "/api/v1/settings", params: params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /api/v1/settings/:id" do
    let(:setting) { create(:setting, user: user) }

    it "updates the setting" do
      patch "/api/v1/settings/#{setting.id}", params: {
        setting: {
          hard_interval: { days: 2, hours: 0, minutes: 0 }
        }
      }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["hard_interval"]).to eq({ "days" => 2, "hours" => 0, "minutes" => 0 })
    end
  end

  describe "DELETE /api/v1/settings/:id" do
    it "deletes the setting" do
      setting = create(:setting, user: user)

      expect {
        delete "/api/v1/settings/#{setting.id}"
      }.to change(Setting, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
