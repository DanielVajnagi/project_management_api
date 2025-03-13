RSpec.describe 'Tasks API', type: :request do
  let(:user) { create(:user) }  # Assuming a user factory exists
  let(:project) { create(:project, user: user) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{user.authentication_token}" } }

  describe 'GET /api/projects/:project_id/tasks' do
    it 'returns all tasks for a project' do
      task1 = create(:task, project: project)
      task2 = create(:task, project: project)

      get api_project_tasks_path(project), headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json.size).to eq(2)
      expect(json[0]['title']).to eq(task1.title)
      expect(json[1]['title']).to eq(task2.title)
    end

    it 'returns unauthorized if no token is provided' do
      get api_project_tasks_path(project)

      expect(response).to have_http_status(:unauthorized)
      expect(json['error']).to eq('Unauthorized')
    end
  end

  describe 'POST /api/projects/:project_id/tasks' do
    context 'with valid attributes' do
      it 'creates a new task for the project' do
        valid_attributes = { task: { title: 'New Task', description: 'Task description', status: 'not_started' } }

        post api_project_tasks_path(project), params: valid_attributes, headers: auth_headers

        expect(response).to have_http_status(:created)
        expect(json['title']).to eq('New Task')
        expect(json['description']).to eq('Task description')
        expect(json['status']).to eq('not_started')
      end
    end

    context 'with invalid attributes' do
      it 'returns errors when title is missing' do
        invalid_attributes = { task: { title: '', description: 'Task description', status: 'not_started' } }

        post api_project_tasks_path(project), params: invalid_attributes, headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors']).to include("Title can't be blank")
      end
    end

    it 'returns unauthorized if no token is provided' do
      valid_attributes = { task: { title: 'New Task', description: 'Task description', status: 'not_started' } }

      post api_project_tasks_path(project), params: valid_attributes

      expect(response).to have_http_status(:unauthorized)
      expect(json['error']).to eq('Unauthorized')
    end
  end

  describe 'GET /api/projects/:project_id/tasks/:id' do
    let(:task) { create(:task, project: project) }

    it 'returns the requested task' do
      get api_project_task_path(project, task), headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json['title']).to eq(task.title)
      expect(json['description']).to eq(task.description)
    end

    it 'returns not found if the task does not exist' do
      get api_project_task_path(project, id: 'nonexistent'), headers: auth_headers

      expect(response).to have_http_status(:not_found)
      expect(json['error']).to eq('Task not found')
    end
  end

  describe 'PATCH/PUT /api/projects/:project_id/tasks/:id' do
    let(:task) { create(:task, project: project) }

    context 'with valid attributes' do
      it 'updates the task' do
        valid_attributes = { task: { title: 'Updated Task', description: 'Updated description', status: 'in_progress' } }

        put api_project_task_path(project, task), params: valid_attributes, headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(json['title']).to eq('Updated Task')
        expect(json['description']).to eq('Updated description')
        expect(json['status']).to eq('in_progress')
      end
    end

    context 'with invalid attributes' do
      it 'returns errors when title is missing' do
        invalid_attributes = { task: { title: '', description: 'Updated description', status: 'in_progress' } }

        put api_project_task_path(project, task), params: invalid_attributes, headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors']).to include("Title can't be blank")
      end
    end
  end

  describe 'DELETE /api/projects/:project_id/tasks/:id' do
    let(:task) { create(:task, project: project) }

    it 'deletes the task' do
      delete api_project_task_path(project, task), headers: auth_headers

      expect(response).to have_http_status(:no_content)
      expect { task.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns not found if the task does not exist' do
      delete api_project_task_path(project, id: 'nonexistent'), headers: auth_headers

      expect(response).to have_http_status(:not_found)
      expect(json['error']).to eq('Task not found')
    end
  end
end
