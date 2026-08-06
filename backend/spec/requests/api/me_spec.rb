require "rails_helper"

RSpec.describe "Api::Me", type: :request do
  describe "GET /api/me" do
    it "returns the current user with a valid token" do
      user = create(:user)
      token = JsonWebToken.encode(user_id: user.id)

      get "/api/me", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({ "id" => user.id, "email" => user.email })
    end

    it "returns unauthorized without a token" do
      get "/api/me"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized with an invalid token" do
      get "/api/me", headers: { "Authorization" => "Bearer invalid-token" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
