# AI(OpenAI)呼び出しは外部APIに依存するため、失敗しても画面を落とさず502を返す。
# ただし握りつぶすと本番で原因を追えないので、例外は必ずログに残す。
module AiErrorHandling
  extend ActiveSupport::Concern

  private

  # 失敗時はエラーJSONをrenderしてnilを返す。呼び出し側は performed? で中断を判断する
  def handle_ai_error(user_message)
    yield
  rescue StandardError => e
    log_ai_error(e)
    render json: { errors: [ user_message ] }, status: :bad_gateway
    nil
  end

  def log_ai_error(error)
    Rails.logger.error("[AI] #{error.class}: #{error.message}")
    Rails.logger.error("[AI] #{error.backtrace.first(5).join("\n")}") if error.backtrace
  end
end
