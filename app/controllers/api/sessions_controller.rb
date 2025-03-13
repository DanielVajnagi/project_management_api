class Api::SessionsController < Devise::SessionsController
  respond_to :json
  include ActionController::MimeResponds

  # POST /api/users/sign_in
  def create
    email = params[:email] || params.dig(:user, :email)
    password = params[:password] || params.dig(:user, :password)

    @user = User.find_for_database_authentication(email: email)
    if @user && @user.valid_password?(password)
      if @user.authentication_token.blank?
        @user.update(authentication_token: SecureRandom.hex(10))
      end
      sign_in @user, store: false
      render json: { token: @user.authentication_token }, status: :created
    else
      render json: { errors: "Invalid credentials" }, status: :unauthorized
    end
  end

  # DELETE /api/users/sign_out
  def destroy
    current_user.update(authentication_token: nil)
    render json: { message: "Logged out" }, status: :ok
  end

  private

  def respond_with(resource, _opts = {})
    render json: { user: resource, authentication_token: resource.authentication_token }, status: :ok
  end
end
