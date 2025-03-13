require 'rails_helper'

RSpec.describe 'Projects API', type: :request do
  let!(:user) { create(:user) }
  let!(:project) { create(:project, user: user) }
  let(:headers) { { 'Authorization' => "Bearer #{user.authentication_token}" } }

  # GET /api/projects
  describe 'GET /api/projects' do
    it 'returns all projects for the user' do
      get '/api/projects', headers: headers

      expect(response).to have_http_status(:success)
      expect(json.size).to eq(1)
      expect(json.first['title']).to eq(project.title)
    end

    it 'returns unauthorized when no token is provided' do
      get '/api/projects'

      expect(response).to have_http_status(:unauthorized)
      expect(json['error']).to eq('Unauthorized')
    end
  end

  # GET /api/projects/:id
  describe 'GET /api/projects/:id' do
    it 'returns a specific project for the user' do
      get "/api/projects/#{project.id}", headers: headers

      expect(response).to have_http_status(:success)
      expect(json['title']).to eq(project.title)
    end

    it 'returns not found if the project does not exist' do
      get '/api/projects/0', headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json['error']).to eq('Project not found')
    end
  end

  # POST /api/projects
  describe 'POST /api/projects' do
    let(:valid_attributes) { { project: { title: 'New Project', description: 'A new project description' } } }
    let(:invalid_attributes) { { project: { title: '', description: 'Invalid project without title' } } }

    it 'creates a new project for the user' do
      post '/api/projects', params: valid_attributes, headers: headers

      expect(response).to have_http_status(:created)
      expect(json['title']).to eq('New Project')
    end

    it 'returns unprocessable_entity when project is invalid' do
      post '/api/projects', params: invalid_attributes, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['errors']).to include("Title can't be blank")
    end

    it 'returns unauthorized when no token is provided' do
      post '/api/projects', params: valid_attributes

      expect(response).to have_http_status(:unauthorized)
      expect(json['error']).to eq('Unauthorized')
    end
  end

  # PATCH/PUT /api/projects/:id
  describe 'PUT /api/projects/:id' do
    let(:valid_attributes) { { project: { title: 'Updated Project Title', description: 'Updated description' } } }
    let(:invalid_attributes) { { project: { title: '', description: 'Invalid project update' } } }

    it 'updates an existing project' do
      put "/api/projects/#{project.id}", params: valid_attributes, headers: headers

      expect(response).to have_http_status(:success)
      expect(json['title']).to eq('Updated Project Title')
    end

    it 'returns unprocessable_entity when project is invalid' do
      put "/api/projects/#{project.id}", params: invalid_attributes, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['errors']).to include("Title can't be blank")
    end

    it 'returns not found when project does not exist' do
      put '/api/projects/0', params: valid_attributes, headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json['error']).to eq('Project not found')
    end
  end

  # DELETE /api/projects/:id
  describe 'DELETE /api/projects/:id' do
    it 'deletes the project' do
      delete "/api/projects/#{project.id}", headers: headers

      expect(response).to have_http_status(:no_content)
    end

    it 'returns not found when project does not exist' do
      delete '/api/projects/0', headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json['error']).to eq('Project not found')
    end
  end
end
