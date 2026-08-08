require "rails_helper"

RSpec.describe "Api::Users", type: :request do
  describe "POST /api/users" do
    it "creates a new user with valid params" do
      expect {
        post "/api/users", params: { user: { nickname: "たろう", email: "new@example.com", password: "password123" } }
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)).to eq({ "id" => User.last.id, "nickname" => "たろう", "email" => "new@example.com" })
    end

    it "returns errors with invalid params" do
      expect {
        post "/api/users", params: { user: { nickname: "たろう", email: "not-an-email", password: "short" } }
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end
  end
end
