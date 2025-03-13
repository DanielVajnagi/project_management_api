class Api::ProjectsController < ApplicationController
  before_action :authenticate_user_from_token!
  before_action :set_project, only: %i[show update destroy]

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

  def authenticate_user_from_token!
    auth_header = request.headers["Authorization"]

    # Check if Authorization header is present and formatted correctly
    if auth_header.nil? || !auth_header.start_with?("Bearer ")
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    token = auth_header.split(" ").last
    user = User.find_by(authentication_token: token)

    if user
      @current_user = user # Set current_user manually
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end


  def set_project
    @project = current_user.projects.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Project not found" }, status: :not_found
  end

  def project_params
    params.require(:project).permit(:title, :description)
  end
end
