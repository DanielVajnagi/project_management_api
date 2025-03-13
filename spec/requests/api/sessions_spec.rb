RSpec.describe 'Sessions API', type: :request do
  let(:user) { create(:user, email: 'user@example.com', password: 'password', password_confirmation: 'password') }
  let(:valid_credentials) { { email: 'user@example.com', password: 'password' } }
  let(:invalid_credentials) { { email: 'user@example.com', password: 'wrongpassword' } }
  let(:auth_headers) { { 'Authorization' => "Bearer #{user.authentication_token}" } }
  let(:headers) { { 'Content-Type' => 'application/json', 'Accept' => 'application/json' } }


  describe 'POST /api/users/sign_in' do
    context 'with valid credentials' do
      it 'returns the authentication token' do
        post api_user_session_path, params: valid_credentials.to_json, headers: headers
        puts response.body
        puts user.password
        puts valid_credentials

        expect(response).to have_http_status(:created)
        expect(json['token']).to be_present
      end
    end

    context 'with invalid credentials' do
      it 'returns an error message' do
        post api_user_session_path, params: invalid_credentials

        expect(response).to have_http_status(:unauthorized)
        expect(json['errors']).to eq('Invalid credentials')
      end
    end
  end

  describe 'DELETE /api/users/sign_out' do
    it 'logs the user out and invalidates the token' do
      delete destroy_api_user_session_path, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json['message']).to eq('Logged out')

      # Verify the token is cleared after logout
      user.reload
      expect(user.authentication_token).to be_nil
    end
  end
end
