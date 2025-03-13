RSpec.describe 'Registrations API', type: :request do
  let(:valid_attributes) { { user: { email: 'user@example.com', password: 'password', password_confirmation: 'password' } } }
  let(:invalid_attributes) { { user: { email: 'user@example.com', password: 'password', password_confirmation: 'wrongpassword' } } }
  let(:missing_password_confirmation) { { user: { email: 'user@example.com', password: 'password' } } }
  let(:missing_email) { { user: { password: 'password', password_confirmation: 'password' } } }

  describe 'POST /api/users' do
    context 'with valid parameters' do
      it 'creates a new user and returns a success message' do
        post api_user_registration_path, params: valid_attributes

        expect(response).to have_http_status(:created)
        expect(json['message']).to eq('User created successfully')
        expect(json['user']['email']).to eq('user@example.com')
      end
    end

    context 'with invalid parameters' do
      it 'returns an error message when password confirmation does not match' do
        post api_user_registration_path, params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors']).to include("Password confirmation doesn't match Password")
      end

      it 'returns an error message when password_confirmation is missing' do
        post api_user_registration_path, params: missing_password_confirmation

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors']).to include("Password confirmation can't be blank")
      end

      it 'returns an error message when email is missing' do
        post api_user_registration_path, params: missing_email

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors']).to include("Email can't be blank")
      end
    end
  end
end
