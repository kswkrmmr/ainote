require "rails_helper"

RSpec.describe "Api::LineLogins", type: :request do
  around do |example|
    ENV["LINE_LOGIN_CHANNEL_ID"] = "1234567890"
    ENV["LINE_LOGIN_CHANNEL_SECRET"] = "login-channel-secret"
    example.run
    ENV.delete("LINE_LOGIN_CHANNEL_ID")
    ENV.delete("LINE_LOGIN_CHANNEL_SECRET")
  end

  describe "GET /api/line/login_url" do
    it "returns LINE's authorization URL without requiring a login" do
      get "/api/line/login_url"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["authorize_url"])
        .to start_with("https://access.line.me/oauth2/v2.1/authorize?")
    end

    it "returns bad_gateway when the login channel is not configured" do
      ENV.delete("LINE_LOGIN_CHANNEL_ID")

      get "/api/line/login_url"

      expect(response).to have_http_status(:bad_gateway)
    end
  end

  describe "POST /api/line/login" do
    def state_for(redirect: nil)
      get "/api/line/login_url", params: { redirect: redirect }.compact
      url = JSON.parse(response.body)["authorize_url"]
      Rack::Utils.parse_query(URI(url).query)["state"]
    end

    it "returns a token for the signed-in LINE user" do
      state = state_for
      stub_request(:post, "https://api.line.me/oauth2/v2.1/token")
        .to_return(status: 200, body: { id_token: "ID_TOKEN" }.to_json)
      stub_request(:post, "https://api.line.me/oauth2/v2.1/verify")
        .to_return(status: 200, body: { sub: "U_LOGIN", name: "たろう" }.to_json)

      post "/api/line/login", params: { code: "CODE", state: state }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["token"]).to be_present
      expect(body["user"]["nickname"]).to eq("たろう")
      expect(body["user"]["email"]).to be_nil
    end

    it "returns unprocessable_entity without a code" do
      post "/api/line/login", params: { state: "something" }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns unauthorized for a forged state" do
      post "/api/line/login", params: { code: "CODE", state: "forged" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
