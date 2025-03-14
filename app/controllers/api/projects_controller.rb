class Api::ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [ :show ]
  before_action :set_project_for_modification, only: [ :update, :destroy ]
  before_action :authorize_owner, only: [ :update, :destroy ]

  # GET /api/projects
  def index
    # Cache the projects list for the current user, expire in 5 minutes
    projects_cache_key = "projects_user_#{current_user.id}"
    @projects = Rails.cache.fetch(projects_cache_key, expires_in: 5.minutes) do
      @projects = current_user.projects
                              .includes(:tasks)
                              .select(:id, :title, :description)
                              .references(:tasks)
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
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/projects/:id
  def update
    if @project.update(project_params)
      # Invalidate cache after updating the project
      Rails.cache.delete("project_user_#{current_user.id}_project_#{@project.id}")
      render json: @project
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/projects/:id
  def destroy
    @project.destroy
    # Invalidate cache after project deletion
    Rails.cache.delete("project_user_#{current_user.id}_project_#{params[:id]}")
    Rails.cache.delete("projects_user_#{current_user.id}")
    head :no_content
  end

  private

  # For show, only the current user's projects are visible.
  def set_project
    @project = current_user.projects.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: :not_found
  end

  # For update and destroy, load the project regardless of the owner,
  # then check ownership in authorize_owner.
  def set_project_for_modification
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: :not_found
  end

  def authorize_owner
    unless @project.user_id == current_user.id
      render json: { error: "You are not authorized to modify this project" }, status: :forbidden
    end
  end

  def project_params
    params.require(:project).permit(:title, :description)
  end
end
