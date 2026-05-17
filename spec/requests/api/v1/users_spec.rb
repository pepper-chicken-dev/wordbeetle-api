require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user) }

  describe 'DELETE /api/v1/users/me' do
    it 'deletes the current user and returns 204' do
      user

      expect do
        delete '/api/v1/users/me', headers: headers
      end.to change(User, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'cascades to associated wordbooks and setting' do
      create(:wordbook, user: user)
      create(:setting, user: user)

      expect do
        delete '/api/v1/users/me', headers: headers
      end.to change(Wordbook, :count).by(-1)
                                     .and change(Setting, :count).by(-1)
    end

    it 'deletes a guest user' do
      guest = create(:user, :guest)
      guest_headers = auth_headers_for(guest)

      expect do
        delete '/api/v1/users/me', headers: guest_headers
      end.to change(User, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns 401 without authentication' do
      delete '/api/v1/users/me'

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
