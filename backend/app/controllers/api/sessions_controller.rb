module Api
  class SessionsController < ApplicationController
    def create
      # Userのnormalizesが前後の空白と大文字小文字を揃えてくれる
      user = User.find_by(email: params[:email].to_s)

      if user&.authenticate(params[:password])
        token = JsonWebToken.encode(user_id: user.id)
        render json: { token: token, user: { id: user.id, nickname: user.nickname, email: user.email } }, status: :ok
      else
        render json: { errors: [ "メールアドレスまたはパスワードが正しくありません" ] }, status: :unauthorized
      end
    end

    def destroy
      head :no_content
    end
  end
end
