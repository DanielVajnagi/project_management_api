class Api::ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [ :show ]
  before_action :set_project_for_modification, only: [ :update, :destroy ]
  before_action :authorize_owner, only: [ :update, :destroy ]

  # GET /api/projects
  def index
    @projects = current_user.projects.includes(:tasks)
    render json: @projects, include: :tasks
  end

  # GET /api/projects/:id
  def show
    render json: @project, include: :tasks
  end

  # POST /api/projects
  def create
    @project = current_user.projects.build(project_params)
    if @project.save
      render json: @project, status: :created
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/projects/:id
  def update
    if @project.update(project_params)
      render json: @project
    else
      render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/projects/:id
  def destroy
    @project.destroy
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
