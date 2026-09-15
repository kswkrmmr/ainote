require "net/http"

# LINE Messaging API を呼び出す。
# Webhookの処理中にも呼ぶため、LINEの応答が遅いときに待ち続けないようタイムアウトを短めにする。
# https://developers.line.biz/en/reference/messaging-api/
class LineClient
  BASE_URL = "https://api.line.me".freeze
  OPEN_TIMEOUT_SECONDS = 5
  READ_TIMEOUT_SECONDS = 10

  class Error < StandardError; end

  class << self
    # アカウント連携用のlinkTokenを発行する。1回限り・10分間有効
    def issue_link_token(line_user_id)
      path = "/v2/bot/user/#{URI.encode_www_form_component(line_user_id)}/linkToken"
      response = request(Net::HTTP::Post, path)
      raise_unless_success(response)
      JSON.parse(response.body)["linkToken"]
    end

    def push_text(line_user_id, text)
      body = { to: line_user_id, messages: [ { type: "text", text: text } ] }
      response = request(Net::HTTP::Post, "/v2/bot/message/push", body)
      raise_unless_success(response)
    end

    def request(klass, path, body = nil)
      token = ENV["LINE_CHANNEL_ACCESS_TOKEN"]
      raise Error, "LINE_CHANNEL_ACCESS_TOKEN が設定されていません" if token.blank?

      uri = URI.join(BASE_URL, path)
      req = klass.new(uri)
      req["Authorization"] = "Bearer #{token}"
      req["Content-Type"] = "application/json"
      req.body = body.to_json if body

      Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: true, open_timeout: OPEN_TIMEOUT_SECONDS, read_timeout: READ_TIMEOUT_SECONDS
      ) { |http| http.request(req) }
    end

    private

    def raise_unless_success(response)
      return if response.is_a?(Net::HTTPSuccess)

      raise Error, "LINE APIの呼び出しに失敗しました (#{response.code}): #{response.body}"
    end
  end
end
