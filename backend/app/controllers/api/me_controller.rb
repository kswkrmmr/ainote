module Api
  class MeController < ApplicationController
    before_action :authenticate_user!

    def show
      render json: { id: current_user.id, nickname: current_user.nickname, email: current_user.email }
    end
  end
end
