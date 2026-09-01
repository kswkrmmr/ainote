require "rails_helper"

RSpec.describe "Api::Me", type: :request do
  describe "GET /api/me" do
    it "returns the current user with a valid token" do
      user = create(:user)
      token = JsonWebToken.encode(user_id: user.id)

      get "/api/me", headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq(
          { "id" => user.id, "nickname" => user.nickname, "email" => user.email, "avatar_url" => nil }
        )
      end

    it "returns unauthorized without a token" do
      get "/api/me"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized with an invalid token" do
      get "/api/me", headers: { "Authorization" => "Bearer invalid-token" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "includes avatar_url when an avatar is attached" do
      user = create(:user)
      user.avatar.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/avatar.png")), filename: "avatar.png", content_type: "image/png"
      )
      token = JsonWebToken.encode(user_id: user.id)

      get "/api/me", headers: { "Authorization" => "Bearer #{token}" }

      expect(JSON.parse(response.body)["avatar_url"]).to be_present
    end
  end

  describe "PATCH /api/me" do
    it "updates the nickname" do
      user = create(:user)
      token = JsonWebToken.encode(user_id: user.id)

      patch "/api/me", params: { nickname: "新しい名前" }, headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["nickname"]).to eq("新しい名前")
      expect(user.reload.nickname).to eq("新しい名前")
    end

    it "updates the avatar" do
      user = create(:user)
      token = JsonWebToken.encode(user_id: user.id)
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/avatar.png"), "image/png")

      patch "/api/me", params: { avatar: file }, headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["avatar_url"]).to be_present
      expect(user.reload.avatar).to be_attached
    end

    it "removes the avatar when remove_avatar is true" do
      user = create(:user)
      user.avatar.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/avatar.png")), filename: "avatar.png", content_type: "image/png"
      )
      token = JsonWebToken.encode(user_id: user.id)

      patch "/api/me", params: { remove_avatar: "true" }, headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["avatar_url"]).to be_nil
      expect(user.reload.avatar).not_to be_attached
    end

    it "ignores remove_avatar when a new avatar is also uploaded" do
      user = create(:user)
      user.avatar.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/avatar.png")), filename: "avatar.png", content_type: "image/png"
      )
      token = JsonWebToken.encode(user_id: user.id)
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/avatar.png"), "image/png")

      patch "/api/me",
        params: { avatar: file, remove_avatar: "true" },
        headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(user.reload.avatar).to be_attached
    end

    it "returns errors with a blank nickname" do
      user = create(:user)
      token = JsonWebToken.encode(user_id: user.id)

      patch "/api/me", params: { nickname: "" }, headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns errors with an oversized avatar" do
      user = create(:user)
      token = JsonWebToken.encode(user_id: user.id)
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/avatar.png"), "image/png")
      allow_any_instance_of(ActiveStorage::Blob).to receive(:byte_size).and_return(10.megabytes)

      patch "/api/me", params: { avatar: file }, headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns unauthorized without a token" do
      patch "/api/me", params: { nickname: "新しい名前" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "updates the email with the correct current_password" do
      user = create(:user, password: "password123")
      token = JsonWebToken.encode(user_id: user.id)

      patch "/api/me",
        params: { email: "new@example.com", current_password: "password123" },
        headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["email"]).to eq("new@example.com")
      expect(user.reload.email).to eq("new@example.com")
    end

    it "rejects an email change without current_password" do
      user = create(:user, password: "password123")
      token = JsonWebToken.encode(user_id: user.id)

      patch "/api/me", params: { email: "new@example.com" }, headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.email).not_to eq("new@example.com")
    end

    it "rejects an email change with an incorrect current_password" do
      user = create(:user, password: "password123")
      token = JsonWebToken.encode(user_id: user.id)

      patch "/api/me",
        params: { email: "new@example.com", current_password: "wrong-password" },
        headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.email).not_to eq("new@example.com")
    end

    it "updates the password with the correct current_password" do
      user = create(:user, password: "password123")
      token = JsonWebToken.encode(user_id: user.id)

      patch "/api/me",
        params: {
          password: "newpassword456",
          password_confirmation: "newpassword456",
          current_password: "password123"
        },
        headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:ok)
      expect(user.reload.authenticate("newpassword456")).to be_truthy
    end

    it "rejects a password change without current_password" do
      user = create(:user, password: "password123")
      token = JsonWebToken.encode(user_id: user.id)

      patch "/api/me",
        params: { password: "newpassword456", password_confirmation: "newpassword456" },
        headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.authenticate("newpassword456")).to be_falsy
    end

    it "returns errors when the new password confirmation does not match" do
      user = create(:user, password: "password123")
      token = JsonWebToken.encode(user_id: user.id)

      patch "/api/me",
        params: {
          password: "newpassword456",
          password_confirmation: "mismatch",
          current_password: "password123"
        },
        headers: { "Authorization" => "Bearer #{token}" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end
  end
end
