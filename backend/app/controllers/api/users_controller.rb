module Api
  class UsersController < ApplicationController
    def create
      user = User.new(user_params)

      if user.save
        render json: { id: user.id, nickname: user.nickname, email: user.email }, status: :created
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(:nickname, :email, :password, :password_confirmation)
    end
  end
end
