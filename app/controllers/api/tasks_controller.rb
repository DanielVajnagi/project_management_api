class Api::TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :authorize_owner
  before_action :set_task, only: [ :show, :update, :destroy ]

  # GET /api/projects/:project_id/tasks
  def index
    # Cache the tasks list for the project, expire in 5 minutes
    tasks_cache_key = "tasks_project_#{@project.id}_status_#{params[:status]}"
    tasks = Rails.cache.fetch(tasks_cache_key, expires_in: 5.minutes) do
      # Apply filtering by status if the "status" parameter is present
      filtered_tasks = @project.tasks
      filtered_tasks = filtered_tasks.where(status: params[:status]) if valid_status_param?

      filtered_tasks.includes(:project).select(:id, :title, :status, :project_id) # Optimize query
    end

    render json: tasks
  end

  # POST /api/projects/:project_id/tasks
  def create
    @task = @project.tasks.build(task_params)
    if @task.save
      # Invalidate cache after a new task is created
      Rails.cache.delete("tasks_project_#{@project.id}_status_#{params[:status]}")
      render json: @task, status: :created
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/projects/:project_id/tasks/:id
  def show
    # Cache the individual task for 5 minutes
    task_cache_key = "task_project_#{@project.id}_task_#{params[:id]}"
    @task = Rails.cache.fetch(task_cache_key, expires_in: 5.minutes) do
      @project.tasks.select(:id, :title, :description, :status).find(params[:id])
    end

    render json: @task
  end

  # PATCH/PUT /api/projects/:project_id/tasks/:id
  def update
    if @task.update(task_params)
      # Invalidate cache after updating the task
      Rails.cache.delete("task_project_#{@project.id}_task_#{@task.id}")
      Rails.cache.delete("tasks_project_#{@project.id}_status_#{params[:status]}") # Remove cached list if needed
      render json: @task
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/projects/:project_id/tasks/:id
  def destroy
    @task.destroy
    # Invalidate cache after task deletion
    Rails.cache.delete("task_project_#{@project.id}_task_#{params[:id]}")
    Rails.cache.delete("tasks_project_#{@project.id}_status_#{params[:status]}") # Remove cached list if needed
    head :no_content
  end

  private

  def set_project
    @project = Project.includes(:tasks).find_by(id: params[:project_id])
    render json: { error: "Project not found" }, status: :not_found unless @project
  end

  def authorize_owner
    unless @project.user_id == current_user.id
      render json: { error: "You are not authorized to modify tasks for this project" }, status: :forbidden
    end
  end

  def set_task
    @task = @project.tasks.find_by(id: params[:id])
    render json: { error: "Task not found" }, status: :not_found unless @task
  end

  def task_params
    params.require(:task).permit(:title, :description, :status)
  end

  def valid_status_param?
    Task.statuses.keys.include?(params[:status]) && params[:status].present?
  end
end
