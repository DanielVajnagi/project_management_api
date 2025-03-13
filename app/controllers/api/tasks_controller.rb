class Api::TasksController < ApplicationController
  include Devise::Controllers::Helpers  # Ensure Devise helpers are available

  before_action :authenticate_user_from_token!
  before_action :set_project
  before_action :set_task, only: %i[show update destroy]

  # GET /api/projects/:project_id/tasks
  def index
    render json: @project.tasks
  end

  # POST /api/projects/:project_id/tasks
  def create
    @task = @project.tasks.build(task_params)
    if @task.save
      render json: @task, status: :created
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/projects/:project_id/tasks/:id
  def show
    render json: @task
  end

  # PATCH/PUT /api/projects/:project_id/tasks/:id
  def update
    if @task.update(task_params)
      render json: @task
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/projects/:project_id/tasks/:id
  def destroy
    @task.destroy
    head :no_content
  end

  private

  def authenticate_user_from_token!
    auth_header = request.headers["Authorization"]

    if auth_header.nil? || !auth_header.start_with?("Bearer ")
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    token = auth_header.split(" ").last
    user = User.find_by(authentication_token: token)

    if user
      @current_user = user
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end


  def set_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: :not_found
  end

  def set_task
    @task = @project.tasks.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Task not found" }, status: :not_found
  end

  def task_params
    params.require(:task).permit(:title, :description, :status)
  end
end
