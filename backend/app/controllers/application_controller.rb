class ApplicationController < ActionController::API
  private

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    decoded = token && JsonWebToken.decode(token)
    @current_user = decoded && User.find_by(id: decoded[:user_id])

    render json: { errors: [ "認証が必要です" ] }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end
end
