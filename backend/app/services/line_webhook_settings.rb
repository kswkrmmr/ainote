require "net/http"

# LINEのWebhook設定APIを叩く。ローカル開発でトンネルのURLが変わるたびに
# LINE側の設定を書き換えるために使う。
# https://developers.line.biz/en/reference/messaging-api/#webhook-settings
class LineWebhookSettings
  BASE_URL = "https://api.line.me".freeze

  class << self
    def set(endpoint)
      request(Net::HTTP::Put, "/v2/bot/channel/webhook/endpoint", { endpoint: endpoint })
    end

    def info
      request(Net::HTTP::Get, "/v2/bot/channel/webhook/endpoint")
    end

    def test
      request(Net::HTTP::Post, "/v2/bot/channel/webhook/test")
    end

    private

    def request(klass, path, body = nil)
      token = ENV["LINE_CHANNEL_ACCESS_TOKEN"]
      raise "LINE_CHANNEL_ACCESS_TOKEN が設定されていません" if token.blank?

      uri = URI.join(BASE_URL, path)
      req = klass.new(uri)
      req["Authorization"] = "Bearer #{token}"
      req["Content-Type"] = "application/json"
      req.body = body.to_json if body

      Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    end
  end
end
