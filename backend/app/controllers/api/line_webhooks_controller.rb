module Api
  # LINEプラットフォームからのWebhookを受ける。
  # 呼び出し元はLINEなのでJWT認証はかけず、代わりに署名でリクエストの正当性を確認する。
  # https://developers.line.biz/en/docs/messaging-api/receiving-messages/
  class LineWebhooksController < ApplicationController
    def create
      # 署名が検証できないリクエストは中身を一切見ずに捨てる
      unless valid_signature?
        head :bad_request
        return
      end

      events.each { |event| handle_event(event) }

      # LINEは短時間での200応答を期待しているため、重い処理はここでは行わない
      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    # X-Line-Signature は「チャネルシークレットを鍵としたリクエストボディのHMAC-SHA256」をBase64にしたもの。
    # パース済みparamsではなく生のボディで計算しないと一致しない。
    def valid_signature?
      secret = ENV["LINE_CHANNEL_SECRET"]
      signature = request.headers["X-Line-Signature"]
      return false if secret.blank? || signature.blank?

      expected = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, request.raw_post))
      ActiveSupport::SecurityUtils.secure_compare(expected, signature)
    end

    def events
      parsed = JSON.parse(request.raw_post)
      parsed.is_a?(Hash) ? Array(parsed["events"]) : []
    end

    def handle_event(event)
      Rails.logger.info("[LINE] received event: #{event["type"]}")

      line_user_id = event.dig("source", "userId")
      return if line_user_id.blank?

      case event["type"]
      when "follow"
        LineAccountLinker.send_link_url(line_user_id)
      when "message"
        LineAccountLinker.send_link_url(line_user_id) if event.dig("message", "text").to_s.strip == "連携"
      when "unfollow"
        LineAccountLinker.unlink(line_user_id)
      when "accountLink"
        LineAccountLinker.complete(line_user_id, event["link"])
      end
    rescue StandardError => e
      # 1件の失敗で他のイベントまで500にすると、LINEの再送で同じ処理が繰り返されうる。
      # ログに残して次のイベントへ進む
      Rails.logger.error("[LINE] failed to handle #{event["type"]}: #{e.class}: #{e.message}")
    end
  end
end
