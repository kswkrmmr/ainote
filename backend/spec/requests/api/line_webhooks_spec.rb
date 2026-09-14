require "rails_helper"

RSpec.describe "Api::LineWebhooks", type: :request do
  let(:channel_secret) { "test-channel-secret" }

  around do |example|
    original = ENV["LINE_CHANNEL_SECRET"]
    ENV["LINE_CHANNEL_SECRET"] = channel_secret
    example.run
    ENV["LINE_CHANNEL_SECRET"] = original
  end

  # コンテナは backend/.env を読むため、テストでも実際のLINEトークンが入っている。
  # イベント処理からLINE APIを呼ばせないよう、連携処理はファイル全体でスタブする
  before do
    allow(LineAccountLinker).to receive(:send_link_url)
    allow(LineAccountLinker).to receive(:unlink)
    allow(LineAccountLinker).to receive(:complete)
  end

  def signature_for(body, secret: channel_secret)
    Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, body))
  end

  def post_webhook(body, signature:)
    post "/api/line/webhook",
      params: body,
      headers: { "X-Line-Signature" => signature, "CONTENT_TYPE" => "application/json" }
  end

  let(:body) do
    {
      destination: "U0123456789abcdef",
      events: [ { type: "follow", source: { type: "user", userId: "U1111" } } ]
    }.to_json
  end

  it "accepts a request with a valid signature" do
    post_webhook(body, signature: signature_for(body))

    expect(response).to have_http_status(:ok)
  end

  it "accepts the verification request that has no events" do
    empty = { destination: "U0123456789abcdef", events: [] }.to_json

    post_webhook(empty, signature: signature_for(empty))

    expect(response).to have_http_status(:ok)
  end

  it "rejects a request signed with the wrong secret" do
    post_webhook(body, signature: signature_for(body, secret: "wrong-secret"))

    expect(response).to have_http_status(:bad_request)
  end

  it "rejects a request whose body was tampered with after signing" do
    signature = signature_for(body)
    tampered = body.sub("U1111", "U9999")

    post_webhook(tampered, signature: signature)

    expect(response).to have_http_status(:bad_request)
  end

  it "rejects a request without a signature header" do
    post "/api/line/webhook", params: body, headers: { "CONTENT_TYPE" => "application/json" }

    expect(response).to have_http_status(:bad_request)
  end

  it "rejects a request when the channel secret is not configured" do
    ENV["LINE_CHANNEL_SECRET"] = nil

    post_webhook(body, signature: signature_for(body))

    expect(response).to have_http_status(:bad_request)
  end

  it "returns bad_request for a valid signature over a non-JSON body" do
    broken = "not json"

    post_webhook(broken, signature: signature_for(broken))

    expect(response).to have_http_status(:bad_request)
  end

  it "does not require a logged-in user" do
    post_webhook(body, signature: signature_for(body))

    expect(response).not_to have_http_status(:unauthorized)
  end

  it "logs the type of each received event" do
    allow(Rails.logger).to receive(:info)

    post_webhook(body, signature: signature_for(body))

    expect(Rails.logger).to have_received(:info).with(/\[LINE\] received event: follow/)
  end

  describe "event handling" do
    def post_events(*events)
      payload = { destination: "U0123456789abcdef", events: events }.to_json
      post_webhook(payload, signature: signature_for(payload))
    end

    it "sends a link URL when a user adds the account as a friend" do
      post_events({ type: "follow", source: { type: "user", userId: "U1111" } })

      expect(LineAccountLinker).to have_received(:send_link_url).with("U1111")
    end

    it "resends the link URL when the user sends「連携」" do
      post_events({ type: "message", source: { userId: "U1111" }, message: { type: "text", text: " 連携 " } })

      expect(LineAccountLinker).to have_received(:send_link_url).with("U1111")
    end

    it "ignores other messages" do
      post_events({ type: "message", source: { userId: "U1111" }, message: { type: "text", text: "こんにちは" } })

      expect(LineAccountLinker).not_to have_received(:send_link_url)
    end

    it "unlinks the account when the user blocks it" do
      post_events({ type: "unfollow", source: { userId: "U1111" } })

      expect(LineAccountLinker).to have_received(:unlink).with("U1111")
    end

    it "completes linking on an accountLink event" do
      post_events({ type: "accountLink", source: { userId: "U1111" }, link: { result: "ok", nonce: "NONCE" } })

      expect(LineAccountLinker).to have_received(:complete).with("U1111", { "result" => "ok", "nonce" => "NONCE" })
    end

    it "ignores events without a user id" do
      post_events({ type: "follow", source: { type: "group", groupId: "C1111" } })

      expect(LineAccountLinker).not_to have_received(:send_link_url)
    end

    it "keeps processing the remaining events and returns ok when one of them fails" do
      allow(LineAccountLinker).to receive(:send_link_url).and_raise(LineClient::Error, "boom")

      post_events(
        { type: "follow", source: { userId: "U1111" } },
        { type: "unfollow", source: { userId: "U2222" } }
      )

      expect(response).to have_http_status(:ok)
      expect(LineAccountLinker).to have_received(:unlink).with("U2222")
    end
  end
end
