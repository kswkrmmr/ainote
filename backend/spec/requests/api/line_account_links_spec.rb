require "rails_helper"

RSpec.describe "Api::LineAccountLinks", type: :request do
  let(:user) { create(:user) }
  let(:headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: user.id)}" } }

  describe "POST /api/line/account_link" do
    it "returns the LINE account-link URL for the logged-in user" do
      post "/api/line/account_link", params: { link_token: "LINKTOKEN" }, headers: headers

      expect(response).to have_http_status(:created)
      redirect_url = JSON.parse(response.body)["redirect_url"]
      query = Rack::Utils.parse_query(URI(redirect_url).query)
      expect(query["linkToken"]).to eq("LINKTOKEN")
      expect(query["nonce"]).to eq(user.line_account_links.last.nonce)
    end

    it "returns unprocessable_entity without a link token" do
      post "/api/line/account_link", params: { link_token: "" }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.line_account_links).to be_empty
    end

    it "returns unauthorized without a token" do
      post "/api/line/account_link", params: { link_token: "LINKTOKEN" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/line/account_link" do
    it "unlinks the current user's LINE account and notifies that LINE account" do
      allow(LineAccountLinker).to receive(:notify_unlinked)
      user.update!(line_user_id: "U1111")

      delete "/api/line/account_link", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(user.reload.line_user_id).to be_nil
      expect(LineAccountLinker).to have_received(:notify_unlinked).with("U1111")
    end

    it "does not send a notification when the user was not linked" do
      allow(LineAccountLinker).to receive(:notify_unlinked)

      delete "/api/line/account_link", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(LineAccountLinker).not_to have_received(:notify_unlinked)
    end

    it "still unlinks when the notification cannot be delivered" do
      allow(LineClient).to receive(:push_text).and_raise(LineClient::Error, "boom")
      user.update!(line_user_id: "U1111")

      delete "/api/line/account_link", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(user.reload.line_user_id).to be_nil
    end

    it "refuses to unlink an account created by LINE login" do
      line_user = create(:user, :line_only)
      headers = { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: line_user.id)}" }

      delete "/api/line/account_link", headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"].first).to include("ログインできなくなります")
      expect(line_user.reload.line_user_id).to be_present
    end

    it "returns unauthorized without a token" do
      delete "/api/line/account_link"

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
