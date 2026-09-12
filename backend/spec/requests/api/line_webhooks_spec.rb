require "rails_helper"

RSpec.describe "Api::LineWebhooks", type: :request do
  let(:channel_secret) { "test-channel-secret" }

  around do |example|
    original = ENV["LINE_CHANNEL_SECRET"]
    ENV["LINE_CHANNEL_SECRET"] = channel_secret
    example.run
    ENV["LINE_CHANNEL_SECRET"] = original
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
end
