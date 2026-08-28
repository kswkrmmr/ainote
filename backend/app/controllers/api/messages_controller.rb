module Api
  class MessagesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_theme

    def index
      render json: @theme.messages.order(:created_at).map { |message| message_json(message) }
    end

    def preview
      original_body = preview_params[:original_body]

      if original_body.blank?
        render json: { errors: [ "本文を入力してください" ] }, status: :unprocessable_entity
        return
      end

      translated_body = translate(original_body)
      return if performed?

      render json: { translated_body: translated_body }
    end

    def create
      message = @theme.messages.build(create_params.merge(user: current_user))

      if message.save
        MessagesChannel.broadcast_to(@theme, message_json(message))
        render json: message_json(message), status: :created
      else
        render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def translate(text)
      MessageTranslator.translate(text)
    rescue StandardError
      render json: { errors: [ "AI変換に失敗しました。もう一度お試しください。" ] }, status: :bad_gateway
      nil
    end

    def preview_params
      params.require(:message).permit(:original_body)
    end

    def create_params
      params.require(:message).permit(:original_body, :translated_body)
    end

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
