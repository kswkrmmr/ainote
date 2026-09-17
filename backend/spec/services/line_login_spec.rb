require "rails_helper"

RSpec.describe LineLogin do
  around do |example|
    ENV["LINE_LOGIN_CHANNEL_ID"] = "1234567890"
    ENV["LINE_LOGIN_CHANNEL_SECRET"] = "login-channel-secret"
    example.run
    ENV.delete("LINE_LOGIN_CHANNEL_ID")
    ENV.delete("LINE_LOGIN_CHANNEL_SECRET")
  end

  def query_of(url)
    Rack::Utils.parse_query(URI(url).query)
  end

  describe ".authorize_url" do
    it "builds LINE's authorization URL with the channel and callback" do
      query = query_of(described_class.authorize_url)

      expect(described_class.authorize_url).to start_with("https://access.line.me/oauth2/v2.1/authorize?")
      expect(query["response_type"]).to eq("code")
      expect(query["client_id"]).to eq("1234567890")
      expect(query["redirect_uri"]).to eq("http://localhost:5173/line/callback")
      expect(query["scope"]).to eq("profile openid")
    end

    it "asks LINE to offer adding the official account as a friend" do
      expect(query_of(described_class.authorize_url)["bot_prompt"]).to eq("aggressive")
    end

    it "uses a different state and nonce every time" do
      first = query_of(described_class.authorize_url)
      second = query_of(described_class.authorize_url)

      expect(first["state"]).not_to eq(second["state"])
      expect(first["nonce"]).not_to eq(second["nonce"])
    end
  end

  describe ".sign_in" do
    let(:state) { query_of(described_class.authorize_url(redirect: redirect))["state"] }
    let(:nonce) { query_of(described_class.authorize_url)["nonce"] }
    let(:redirect) { nil }

    def stub_line(sub: "U_LOGIN", name: "たろう")
      stub_request(:post, "https://api.line.me/oauth2/v2.1/token")
        .to_return(status: 200, body: { id_token: "ID_TOKEN", access_token: "A" }.to_json)
      stub_request(:post, "https://api.line.me/oauth2/v2.1/verify")
        .to_return(status: 200, body: { sub: sub, name: name }.to_json)
    end

    it "creates a LINE-only account for a first-time user" do
      stub_line

      result = nil
      expect { result = described_class.sign_in(code: "CODE", state: state) }.to change(User, :count).by(1)

      user = result[:user]
      expect(user.line_user_id).to eq("U_LOGIN")
      expect(user.nickname).to eq("たろう")
      expect(user.email).to be_nil
      expect(user.password_digest).to be_nil
      expect(user).to be_line_only
    end

    it "signs in the existing user when the LINE account is already known" do
      stub_line
      existing = create(:user, line_user_id: "U_LOGIN")

      result = nil
      expect { result = described_class.sign_in(code: "CODE", state: state) }.not_to change(User, :count)

      expect(result[:user]).to eq(existing)
    end

    it "sends the code and the nonce from the state to LINE" do
      stub_line
      generated = query_of(described_class.authorize_url)

      described_class.sign_in(code: "CODE", state: generated["state"])

      expect(WebMock).to have_requested(:post, "https://api.line.me/oauth2/v2.1/token")
        .with(body: hash_including("code" => "CODE", "client_secret" => "login-channel-secret"))
      expect(WebMock).to have_requested(:post, "https://api.line.me/oauth2/v2.1/verify")
        .with(body: hash_including("id_token" => "ID_TOKEN", "nonce" => generated["nonce"]))
    end

    it "falls back to a default nickname when LINE returns no name" do
      stub_line(name: nil)

      expect(described_class.sign_in(code: "CODE", state: state)[:user].nickname).to eq("LINEユーザー")
    end

    it "rejects a state that was not signed by us" do
      stub_line

      expect { described_class.sign_in(code: "CODE", state: "forged-state") }
        .to raise_error(described_class::Error)
    end

    it "rejects an expired state" do
      stub_line
      expired = state

      travel_to(11.minutes.from_now) do
        expect { described_class.sign_in(code: "CODE", state: expired) }.to raise_error(described_class::Error)
      end
    end

    it "raises when LINE rejects the code" do
      stub_request(:post, "https://api.line.me/oauth2/v2.1/token").to_return(status: 400, body: "{}")

      expect { described_class.sign_in(code: "CODE", state: state) }.to raise_error(described_class::Error)
    end

    context "with a redirect target" do
      let(:redirect) { "/invitations/abc123" }

      it "keeps an allowed redirect through the login" do
        stub_line

        expect(described_class.sign_in(code: "CODE", state: state)[:redirect]).to eq("/invitations/abc123")
      end
    end

    context "with a redirect to another site" do
      let(:redirect) { "https://evil.example.com" }

      it "drops it" do
        stub_line

        expect(described_class.sign_in(code: "CODE", state: state)[:redirect]).to be_nil
      end
    end
  end
end
