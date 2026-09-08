module Api
  class VentChatsController < ApplicationController
    include AiErrorHandling

    # roleをクライアントに自由に指定させると、systemを送ってプロンプトを差し替えられてしまう
    ALLOWED_ROLES = %w[user assistant].freeze

    # 履歴はクライアントが毎回まとめて送ってくるため、上限がないと会話が続くほど
    # トークン量が際限なく増える。直近のやり取りだけをAIに渡す
    MAX_HISTORY_SIZE = 20

    before_action :authenticate_user!

    def create
      history = chat_history

      if invalid_roles?(history)
        render json: { errors: [ "不正なリクエストです" ] }, status: :unprocessable_entity
        return
      end

      if history.blank? || history.last[:content].blank?
        render json: { errors: [ "内容を入力してください" ] }, status: :unprocessable_entity
        return
      end

      reply = generate_reply(history.last(MAX_HISTORY_SIZE))
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

    def invalid_roles?(history)
      history.any? { |message| ALLOWED_ROLES.exclude?(message[:role]) }
    end
  end
end
