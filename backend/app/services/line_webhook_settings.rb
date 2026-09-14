# LINEのWebhook設定APIを叩く。ローカル開発でトンネルのURLが変わるたびに
# LINE側の設定を書き換えるために使う。
# https://developers.line.biz/en/reference/messaging-api/#webhook-settings
class LineWebhookSettings
  class << self
    def set(endpoint)
      LineClient.request(Net::HTTP::Put, "/v2/bot/channel/webhook/endpoint", { endpoint: endpoint })
    end

    def info
      LineClient.request(Net::HTTP::Get, "/v2/bot/channel/webhook/endpoint")
    end

    def test
      LineClient.request(Net::HTTP::Post, "/v2/bot/channel/webhook/test")
    end
  end
end
