require "rails_helper"

RSpec.describe "Api::Sessions", type: :request do
  let!(:user) { create(:user, email: "user@example.com", password: "password123") }

  describe "POST /api/login" do
    it "returns a token with valid credentials" do
      post "/api/login", params: { email: "user@example.com", password: "password123" }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["token"]).to be_present
      expect(body["user"]).to eq({ "id" => user.id, "email" => user.email })
    end

    it "returns unauthorized with an incorrect password" do
      post "/api/login", params: { email: "user@example.com", password: "wrongpassword" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized with a non-existent email" do
      post "/api/login", params: { email: "nobody@example.com", password: "password123" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/logout" do
    it "returns no content" do
      delete "/api/logout"

      expect(response).to have_http_status(:no_content)
    end
  end
end
