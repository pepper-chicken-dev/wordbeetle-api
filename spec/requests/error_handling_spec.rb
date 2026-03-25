require "rails_helper"

RSpec.describe "Error handling", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe "ActionController::ParameterMissing" do
    it "returns bad_request when required parameter key is missing" do
      post "/api/v1/wordbooks", params: {}, headers: headers

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]).to be_present
    end
  end

  describe "ActiveRecord::RecordNotFound" do
    it "returns not_found for nonexistent resource" do
      get "/api/v1/wordbooks/999999", headers: headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error"]).to eq("Not found")
    end
  end
end
