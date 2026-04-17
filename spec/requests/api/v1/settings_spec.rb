require 'rails_helper'

RSpec.describe 'Api::V1::Settings', type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe 'GET /api/v1/setting' do
    it "returns the current user's setting" do
      create(:setting, user: user)

      get '/api/v1/setting', headers: headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['hard_interval']).to eq({ 'days' => 1, 'hours' => 0, 'minutes' => 0 })
      expect(body['uncertain_interval']).to eq({ 'days' => 3, 'hours' => 0, 'minutes' => 0 })
      expect(body['easy_interval']).to eq({ 'days' => 7, 'hours' => 0, 'minutes' => 0 })
    end

    it 'returns default values when user has no setting' do
      get '/api/v1/setting', headers: headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['hard_interval']).to eq({ 'days' => 1, 'hours' => 0, 'minutes' => 0 })
      expect(body['uncertain_interval']).to eq({ 'days' => 3, 'hours' => 0, 'minutes' => 0 })
      expect(body['easy_interval']).to eq({ 'days' => 7, 'hours' => 0, 'minutes' => 0 })
      expect(body).not_to have_key('id')
    end

    it 'returns 401 without authentication' do
      get '/api/v1/setting'

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/setting' do
    context 'with valid params' do
      it 'creates a setting for the current user' do
        params = {
          setting: {
            hard_interval: { days: 1, hours: 0, minutes: 0 },
            uncertain_interval: { days: 3, hours: 0, minutes: 0 },
            easy_interval: { days: 7, hours: 0, minutes: 0 }
          }
        }

        expect do
          post '/api/v1/setting', params: params, headers: headers
        end.to change(Setting, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(Setting.last.user_id).to eq(user.id)
      end
    end

    context 'with missing intervals' do
      it 'returns unprocessable_content' do
        params = {
          setting: {
            hard_interval: { days: 1, hours: 0, minutes: 0 }
          }
        }

        post '/api/v1/setting', params: params, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'with intervals not in ascending order' do
      it 'returns unprocessable_content with error message' do
        params = {
          setting: {
            hard_interval: { days: 5, hours: 0, minutes: 0 },
            uncertain_interval: { days: 1, hours: 0, minutes: 0 },
            easy_interval: { days: 7, hours: 0, minutes: 0 }
          }
        }

        post '/api/v1/setting', params: params, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['error']).to eq('Unprocessable entity')
      end
    end
  end

  describe 'PATCH /api/v1/setting' do
    let!(:setting) { create(:setting, user: user) }

    it 'updates the setting' do
      patch '/api/v1/setting', params: {
        setting: {
          hard_interval: { days: 2, hours: 0, minutes: 0 }
        }
      }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['hard_interval']).to eq({ 'days' => 2, 'hours' => 0, 'minutes' => 0 })
    end

    context 'with intervals not in ascending order' do
      it 'returns unprocessable_content with error message' do
        patch '/api/v1/setting', params: {
          setting: {
            hard_interval: { days: 1, hours: 0, minutes: 0 },
            uncertain_interval: { days: 10, hours: 0, minutes: 0 },
            easy_interval: { days: 3, hours: 0, minutes: 0 }
          }
        }, headers: headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body['error']).to eq('Unprocessable entity')
      end
    end
  end

  describe 'DELETE /api/v1/setting' do
    it 'deletes the setting' do
      create(:setting, user: user)

      expect do
        delete '/api/v1/setting', headers: headers
      end.to change(Setting, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
