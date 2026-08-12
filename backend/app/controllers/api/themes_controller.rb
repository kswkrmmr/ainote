module Api
  class ThemesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_room

    def create
      theme = @room.themes.build(theme_params.merge(user: current_user))

      if theme.save
        render json: { id: theme.id, title: theme.title }, status: :created
      else
        render json: { errors: theme.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def set_room
      room_member = current_user.room_members.find_by(room_id: params[:room_id])

      if room_member
        @room = room_member.room
      else
        render json: { errors: [ "ルームが見つかりません" ] }, status: :not_found
      end
    end

    def theme_params
      params.require(:theme).permit(:title)
    end
  end
end
