class Api::TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :authorize_owner
  before_action :set_task, only: [:show, :update, :destroy]

  # GET /api/projects/:project_id/tasks
  def index
    tasks = @project.tasks
    # If the "status" parameter is provided and is not empty, apply filtering.
    if params[:status].present? && Task.statuses.keys.include?(params[:status])
      tasks = tasks.where(status: params[:status])
    end
    render json: tasks
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

  def set_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: :not_found
  end

  def authorize_owner
    unless @project.user_id == current_user.id
      render json: { error: "You are not authorized to modify tasks for this project" }, status: :forbidden
    end
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
