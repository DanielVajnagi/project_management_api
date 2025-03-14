# spec/requests/api/projects_spec.rb
require 'rails_helper'
require 'devise/jwt/test_helpers'  # Ensure the helper is loaded

RSpec.describe 'Api::Projects', type: :request do
  let(:user) { create(:user) }
  # Use the JWT test helper to add the token to headers.
  # The first argument is an empty hash that will be augmented.
  let(:headers) { Devise::JWT::TestHelpers.auth_headers({}, user) }

  describe 'GET /api/projects' do
    it 'returns a list of projects for the authenticated user' do
      create(:project, user: user)

      get '/api/projects', headers: headers

      expect(response).to have_http_status(:ok)
      projects = JSON.parse(response.body)
      expect(projects).not_to be_empty
      expect(projects.first['user_id']).to eq(user.id)
    end
  end

  describe 'GET /api/projects/:id' do
    let(:project) { create(:project, user: user) }

    it 'returns the project details when it exists' do
      get "/api/projects/#{project.id}", headers: headers

      expect(response).to have_http_status(:ok)
      project_response = JSON.parse(response.body)
      expect(project_response['id']).to eq(project.id)
    end

    it 'returns a not found error when the project does not exist' do
      get '/api/projects/99999', headers: headers

      expect(response).to have_http_status(:not_found)
      error_response = JSON.parse(response.body)
      expect(error_response['error']).to eq('Project not found')
    end
  end

  describe 'POST /api/projects' do
    let(:valid_attributes) { { title: 'New Project', description: 'Test description' } }
    let(:invalid_attributes) { { title: '', description: 'Test description' } }

    it 'creates a new project with valid attributes' do
      expect {
        post '/api/projects', params: { project: valid_attributes }, headers: headers
      }.to change(Project, :count).by(1)

      expect(response).to have_http_status(:created)
      project_response = JSON.parse(response.body)
      expect(project_response['title']).to eq('New Project')
    end

    it 'returns an error for invalid attributes' do
      post '/api/projects', params: { project: invalid_attributes }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      error_response = JSON.parse(response.body)
      expect(error_response['errors']).to include("Title can't be blank")
    end
  end

  describe 'PATCH /api/projects/:id' do
    let!(:project) { create(:project, user: user, title: 'Original Title') }

    it 'updates the project when it belongs to the authenticated user' do
      patch "/api/projects/#{project.id}", params: { project: { title: 'Updated Title' } }, headers: headers

      expect(response).to have_http_status(:ok)
      project.reload
      expect(project.title).to eq('Updated Title')
    end

    it 'returns forbidden when trying to update a project not owned by the user' do
      other_user = create(:user)
      other_project = create(:project, user: other_user, title: 'Other Title')

      patch "/api/projects/#{other_project.id}", params: { project: { title: 'Hacked Title' } }, headers: headers

      expect(response).to have_http_status(:forbidden)
      other_project.reload
      expect(other_project.title).to eq('Other Title')
    end
  end

  describe 'DELETE /api/projects/:id' do
    let!(:project) { create(:project, user: user) }

    it 'deletes the project when it belongs to the authenticated user' do
      expect {
        delete "/api/projects/#{project.id}", headers: headers
      }.to change(Project, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns forbidden when trying to delete a project not owned by the user' do
      other_user = create(:user)
      other_project = create(:project, user: other_user)

      delete "/api/projects/#{other_project.id}", headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(Project.exists?(other_project.id)).to be_truthy
    end
  end
end
