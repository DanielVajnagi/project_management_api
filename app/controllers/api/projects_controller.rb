class Api::ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [ :show, :update, :destroy ]

  # GET /api/projects
  def index
    # Cache the projects list for the current user, expire in 5 minutes
    projects_cache_key = "projects_user_#{current_user.id}"
    @projects = Rails.cache.fetch(projects_cache_key, expires_in: 5.minutes) do
      current_user.projects.includes(:tasks).select(:id, :title, :description)
    end
    render json: @projects, include: { tasks: { only: [ :id, :title, :status ] } }
  end

  # GET /api/projects/:id
  def show
    # Cache the individual project with its tasks for 5 minutes
    project_cache_key = "project_user_#{current_user.id}_project_#{params[:id]}"
    @project = Rails.cache.fetch(project_cache_key, expires_in: 5.minutes) do
      current_user.projects.includes(:tasks).select(:id, :title, :description).find_by(id: params[:id])
    end
    return render_not_found unless @project
    render json: @project, include: { tasks: { only: [ :id, :title, :status ] } }
  end

  # POST /api/projects
  def create
    @project = current_user.projects.build(project_params)
    if @project.save
      # Invalidate cache after a new project is created
      Rails.cache.delete("projects_user_#{current_user.id}")
      render json: @project, status: :created
    else
      render_validation_errors(@project)
    end
  end

  # PATCH/PUT /api/projects/:id
  def update
    if @project.update(project_params)
      # Invalidate cache after updating the project
      Rails.cache.delete("project_user_#{current_user.id}_project_#{@project.id}")
      Rails.cache.delete("projects_user_#{current_user.id}")
      render json: @project
    else
      render_validation_errors(@project)
    end
  end

  # DELETE /api/projects/:id
  def destroy
    @project.destroy
    # Invalidate cache after project deletion
    Rails.cache.delete("project_user_#{current_user.id}_project_#{@project.id}")
    Rails.cache.delete("projects_user_#{current_user.id}")
    render json: { message: "Project successfully deleted" }, status: :ok
  end

  private

  # For show, only the current user's projects are visible.
  def set_project
    @project = current_user.projects.find_by(id: params[:id])
    render_not_found unless @project
  end

  def project_params
    params.require(:project).permit(:title, :description)
  end

  def render_validation_errors(project)
    render json: { errors: project.errors.full_messages }, status: :unprocessable_entity
  end

  def render_not_found
    render json: { error: "Project not found or you are not authorized to modify it" }, status: :not_found
  end
end
