require "rails_helper"

RSpec.describe "Api::Themes", type: :request do
  let(:user) { create(:user) }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }
  let(:room) { create(:room, owner: user) }
  let(:room_member) { create(:room_member, room: room, user: user, partner_display_name: "妻") }

  describe "GET /api/themes/:id" do
    it "returns the theme with its room_id" do
      room_member
      theme = create(:theme, room: room, user: user, title: "家事について")

      get "/api/themes/#{theme.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        { "id" => theme.id, "title" => "家事について", "room_id" => room.id }
      )
    end

    it "returns not_found for a theme belonging to a room the current user is not a member of" do
      other_theme = create(:theme)

      get "/api/themes/#{other_theme.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns unauthorized without a token" do
      room_member
      theme = create(:theme, room: room, user: user)

      get "/api/themes/#{theme.id}"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "DELETE /api/themes/:id" do
    it "deletes the theme and its messages" do
      room_member
      theme = create(:theme, room: room, user: user)
      create(:message, theme: theme, user: user)

      expect {
        delete "/api/themes/#{theme.id}", headers: headers
      }.to change(Theme, :count).by(-1).and change(Message, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns not_found for a theme belonging to a room the current user is not a member of" do
      other_theme = create(:theme)

      expect {
        delete "/api/themes/#{other_theme.id}", headers: headers
      }.not_to change(Theme, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "returns unauthorized without a token" do
      room_member
      theme = create(:theme, room: room, user: user)

      delete "/api/themes/#{theme.id}"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/rooms/:room_id/themes" do
    it "returns the themes for the room in creation order" do
      room_member
      older_theme = create(:theme, room: room, user: user, title: "家事について", created_at: 1.day.ago)
      newer_theme = create(:theme, room: room, user: user, title: "育児について")

      get "/api/rooms/#{room.id}/themes", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        [
          { "id" => older_theme.id, "title" => "家事について" },
          { "id" => newer_theme.id, "title" => "育児について" }
        ]
      )
    end

    it "returns an empty array when the room has no themes" do
      room_member

      get "/api/rooms/#{room.id}/themes", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it "returns not_found for a room the current user is not a member of" do
      other_room = create(:room)

      get "/api/rooms/#{other_room.id}/themes", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns unauthorized without a token" do
      room_member

      get "/api/rooms/#{room.id}/themes"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/rooms/:room_id/themes" do
    it "creates a theme owned by the current user" do
      room_member

      expect {
        post "/api/rooms/#{room.id}/themes", params: { theme: { title: "家計について" } }, headers: headers
      }.to change(Theme, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)).to eq({ "id" => Theme.last.id, "title" => "家計について" })
      expect(Theme.last.user).to eq(user)
    end

    it "returns errors with a blank title" do
      room_member

      expect {
        post "/api/rooms/#{room.id}/themes", params: { theme: { title: "" } }, headers: headers
      }.not_to change(Theme, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns not_found for a room the current user is not a member of" do
      other_room = create(:room)

      post "/api/rooms/#{other_room.id}/themes", params: { theme: { title: "家計について" } }, headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns unauthorized without a token" do
      room_member

      post "/api/rooms/#{room.id}/themes", params: { theme: { title: "家計について" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
