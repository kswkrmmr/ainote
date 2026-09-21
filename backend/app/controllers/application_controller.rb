class ApplicationController < ActionController::API
  private

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    decoded = token && JsonWebToken.decode(token)
    # 退会済みのアカウントは、発行済みのトークンが残っていても使わせない
    @current_user = decoded && User.active.find_by(id: decoded[:user_id])

    render json: { errors: [ "認証が必要です" ] }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end
end
