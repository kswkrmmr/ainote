# AI(OpenAI)呼び出しは外部APIに依存するため、失敗しても画面を落とさず502を返す。
# ただし握りつぶすと本番で原因を追えないので、例外は必ずログに残す。
module AiErrorHandling
  extend ActiveSupport::Concern

  # 利用上限を超えるとOpenAIは429(code: insufficient_quota)を返す。
  # 再試行しても直らないため、「もう一度お試しください」ではなく停止中であることを伝える
  QUOTA_EXCEEDED_MESSAGE = "現在AI機能を一時停止しています。時間をおいてご利用ください。".freeze

  private

  # 失敗時はエラーJSONをrenderしてnilを返す。呼び出し側は performed? で中断を判断する
  def handle_ai_error(user_message)
    yield
  rescue StandardError => e
    log_ai_error(e)
    if quota_exceeded?(e)
      render json: { errors: [ QUOTA_EXCEEDED_MESSAGE ] }, status: :service_unavailable
    else
      render json: { errors: [ user_message ] }, status: :bad_gateway
    end
    nil
  end

  def quota_exceeded?(error)
    error.is_a?(OpenAI::Errors::RateLimitError) && error.code == "insufficient_quota"
  end

  def log_ai_error(error)
    Rails.logger.error("[AI] #{error.class}: #{error.message}")
    Rails.logger.error("[AI] #{error.backtrace.first(5).join("\n")}") if error.backtrace
  end
end
