module Api
  class VentChatsController < ApplicationController
    include AiErrorHandling

    before_action :authenticate_user!

    def create
      history = chat_history

      if history.blank? || history.last[:content].blank?
        render json: { errors: [ "内容を入力してください" ] }, status: :unprocessable_entity
        return
      end

      reply = generate_reply(history)
      return if performed?

      render json: { reply: reply }
    end

    private

    def generate_reply(history)
      handle_ai_error("AIとの通信に失敗しました。もう一度お試しください。") do
        VentChat.reply(history)
      end
    end

    def chat_history
      messages = params.permit(messages: [ :role, :content ])[:messages] || []
      messages.map { |message| { role: message[:role], content: message[:content] } }
    end
  end
end
