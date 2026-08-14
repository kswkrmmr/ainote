module Api
  class MessagesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_theme

    def index
      render json: @theme.messages.order(:created_at).map { |message| message_json(message) }
    end

    private

    def set_theme
      @theme = Theme.joins(room: :room_members)
        .where(room_members: { user_id: current_user.id })
        .find_by(id: params[:theme_id])

      render json: { errors: [ "テーマが見つかりません" ] }, status: :not_found unless @theme
    end

    def message_json(message)
      {
        id: message.id,
        user_id: message.user_id,
        original_body: message.original_body,
        translated_body: message.translated_body
      }
    end
  end
end
