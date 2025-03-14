# spec/requests/api/tasks_spec.rb
require 'rails_helper'
require 'devise/jwt/test_helpers'

RSpec.describe 'Api::Tasks', type: :request do
  let(:user) { create(:user) }
  # Create a project owned by the user for testing
  let(:project) { create(:project, user: user) }
  # Generate authentication headers using Devise JWT helper
  let(:headers) { Devise::JWT::TestHelpers.auth_headers({}, user) }

  describe 'GET /api/projects/:project_id/tasks' do
    it 'returns a list of tasks for the project' do
      # Create a task associated with the project
      task = create(:task, project: project)

      get "/api/projects/#{project.id}/tasks", headers: headers

      expect(response).to have_http_status(:ok)
      tasks = JSON.parse(response.body)
      expect(tasks).not_to be_empty
      expect(tasks.first['id']).to eq(task.id)
    end

    it 'returns not found if project does not exist' do
      get "/api/projects/99999/tasks", headers: headers

      expect(response).to have_http_status(:not_found)
      error_response = JSON.parse(response.body)
      expect(error_response['error']).to eq('Project not found')
    end
  end

  describe 'GET /api/projects/:project_id/tasks/:id' do
    let(:task) { create(:task, project: project) }

    it 'returns the task details when it exists' do
      get "/api/projects/#{project.id}/tasks/#{task.id}", headers: headers

      expect(response).to have_http_status(:ok)
      task_response = JSON.parse(response.body)
      expect(task_response['id']).to eq(task.id)
    end

    it 'returns a not found error when the task does not exist' do
      get "/api/projects/#{project.id}/tasks/99999", headers: headers

      expect(response).to have_http_status(:not_found)
      error_response = JSON.parse(response.body)
      expect(error_response['error']).to eq('Task not found')
    end
  end

  describe 'POST /api/projects/:project_id/tasks' do
    # Use a valid status value from the enum: not_started, in_progress, or done.
    let(:valid_attributes) { { title: 'New Task', description: 'Test task', status: 'not_started' } }
    let(:invalid_attributes) { { title: '', description: 'Test task', status: 'not_started' } }

    it 'creates a new task with valid attributes' do
      expect {
        post "/api/projects/#{project.id}/tasks", params: { task: valid_attributes }, headers: headers
      }.to change(Task, :count).by(1)

      expect(response).to have_http_status(:created)
      task_response = JSON.parse(response.body)
      expect(task_response['title']).to eq('New Task')
    end

    it 'returns an error for invalid attributes' do
      post "/api/projects/#{project.id}/tasks", params: { task: invalid_attributes }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      error_response = JSON.parse(response.body)
      expect(error_response['errors']).to include("Title can't be blank")
    end
  end

  describe 'PATCH /api/projects/:project_id/tasks/:id' do
    let(:task) { create(:task, project: project, title: 'Old Title') }

    it 'updates the task when it exists and belongs to the project' do
      patch "/api/projects/#{project.id}/tasks/#{task.id}", params: { task: { title: 'Updated Title' } }, headers: headers

      expect(response).to have_http_status(:ok)
      task.reload
      expect(task.title).to eq('Updated Title')
    end

    it 'returns forbidden when trying to update a task in a project not owned by the user' do
      other_user = create(:user)
      other_project = create(:project, user: other_user)
      other_task = create(:task, project: other_project, title: 'Other Task')

      patch "/api/projects/#{other_project.id}/tasks/#{other_task.id}", params: { task: { title: 'Hacked Title' } }, headers: headers

      expect(response).to have_http_status(:forbidden)
      other_task.reload
      expect(other_task.title).to eq('Other Task')
    end
  end

  describe 'DELETE /api/projects/:project_id/tasks/:id' do
    let!(:task) { create(:task, project: project) }

    it 'deletes the task when it belongs to the project' do
      expect {
        delete "/api/projects/#{project.id}/tasks/#{task.id}", headers: headers
      }.to change(Task, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns forbidden when trying to delete a task in a project not owned by the user' do
      other_user = create(:user)
      other_project = create(:project, user: other_user)
      other_task = create(:task, project: other_project)

      delete "/api/projects/#{other_project.id}/tasks/#{other_task.id}", headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(Task.exists?(other_task.id)).to be_truthy
    end
  end
end
