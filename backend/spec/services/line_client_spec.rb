require "rails_helper"

RSpec.describe LineClient do
  around do |example|
    original = ENV["LINE_CHANNEL_ACCESS_TOKEN"]
    ENV["LINE_CHANNEL_ACCESS_TOKEN"] = "test-access-token"
    example.run
    ENV["LINE_CHANNEL_ACCESS_TOKEN"] = original
  end

  describe ".issue_link_token" do
    it "requests a link token for the LINE user and returns it" do
      stub = stub_request(:post, "https://api.line.me/v2/bot/user/U1111/linkToken")
        .with(headers: { "Authorization" => "Bearer test-access-token" })
        .to_return(status: 200, body: { linkToken: "LINKTOKEN" }.to_json)

      expect(described_class.issue_link_token("U1111")).to eq("LINKTOKEN")
      expect(stub).to have_been_requested
    end

    it "raises when LINE responds with an error" do
      stub_request(:post, "https://api.line.me/v2/bot/user/U1111/linkToken")
        .to_return(status: 400, body: { message: "bad request" }.to_json)

      expect { described_class.issue_link_token("U1111") }.to raise_error(LineClient::Error, /400/)
    end
  end

  describe ".push_text" do
    it "sends a text message to the LINE user" do
      stub = stub_request(:post, "https://api.line.me/v2/bot/message/push")
        .with(body: { to: "U1111", messages: [ { type: "text", text: "こんにちは" } ] }.to_json)
        .to_return(status: 200, body: "{}")

      described_class.push_text("U1111", "こんにちは")

      expect(stub).to have_been_requested
    end
  end

  it "raises before calling LINE when the access token is not configured" do
    ENV["LINE_CHANNEL_ACCESS_TOKEN"] = nil

    expect { described_class.push_text("U1111", "hi") }.to raise_error(LineClient::Error, /LINE_CHANNEL_ACCESS_TOKEN/)
  end
end
