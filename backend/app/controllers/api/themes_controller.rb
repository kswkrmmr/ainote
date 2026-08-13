module Api
  class ThemesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_room

    def index
      render json: @room.themes.order(:created_at).map { |theme| theme_json(theme) }
    end

    def create
      theme = @room.themes.build(theme_params.merge(user: current_user))

      if theme.save
        render json: theme_json(theme), status: :created
      else
        render json: { errors: theme.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def theme_json(theme)
      { id: theme.id, title: theme.title }
    end

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
