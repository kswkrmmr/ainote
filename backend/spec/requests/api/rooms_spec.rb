require "rails_helper"

RSpec.describe "Api::Rooms", type: :request do
  let(:user) { create(:user) }
  let(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:headers) { { "Authorization" => "Bearer #{token}" } }

  describe "POST /api/rooms" do
    it "creates a room and a room_member for the owner" do
      expect {
        post "/api/rooms", params: { room: { partner_display_name: "妻" } }, headers: headers
      }.to change(Room, :count).by(1).and change(RoomMember, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)).to eq({ "id" => Room.last.id })
    end

    it "returns errors with a blank partner_display_name" do
      expect {
        post "/api/rooms", params: { room: { partner_display_name: "" } }, headers: headers
      }.not_to change(Room, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns unauthorized without a token" do
      post "/api/rooms", params: { room: { partner_display_name: "妻" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/rooms" do
    it "returns only the rooms the current user is a member of" do
      my_room_member = create(:room_member, user: user, partner_display_name: "妻")
      create(:room_member)

      get "/api/rooms", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        [ { "id" => my_room_member.room_id, "partner_display_name" => "妻", "partner_avatar_url" => nil, "awaiting_partner" => true } ]
      )
    end

    it "marks a room as not awaiting a partner once a second member has joined" do
      my_room_member = create(:room_member, user: user, partner_display_name: "妻")
      create(:room_member, room: my_room_member.room)

      get "/api/rooms", headers: headers

      expect(JSON.parse(response.body)).to eq(
        [ { "id" => my_room_member.room_id, "partner_display_name" => "妻", "partner_avatar_url" => nil, "awaiting_partner" => false } ]
      )
    end

    it "includes the partner's avatar_url when the partner has one attached" do
      my_room_member = create(:room_member, user: user, partner_display_name: "妻")
      partner_member = create(:room_member, room: my_room_member.room)
      partner_member.user.avatar.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/avatar.png")), filename: "avatar.png", content_type: "image/png"
      )

      get "/api/rooms", headers: headers

      expect(JSON.parse(response.body).first["partner_avatar_url"]).to be_present
    end

    it "returns unauthorized without a token" do
      get "/api/rooms"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/rooms/:id" do
    it "returns the room detail" do
      room_member = create(:room_member, user: user, partner_display_name: "父")

      get "/api/rooms/#{room_member.room_id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        { "id" => room_member.room_id, "partner_display_name" => "父", "partner_avatar_url" => nil, "awaiting_partner" => true }
      )
    end

    it "returns not_found for a room the current user is not a member of" do
      other_room_member = create(:room_member)

      get "/api/rooms/#{other_room_member.room_id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns not_found for a non-existent room" do
      get "/api/rooms/999999", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/rooms/:id" do
    it "deletes the room and its associated records" do
      room_member = create(:room_member, user: user, partner_display_name: "妻")
      room = room_member.room
      theme = create(:theme, room: room, user: user)
      create(:message, theme: theme, user: user)

      expect {
        delete "/api/rooms/#{room.id}", headers: headers
      }.to change(Room, :count).by(-1)
        .and change(RoomMember, :count).by(-1)
        .and change(Theme, :count).by(-1)
        .and change(Message, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns not_found for a room the current user is not a member of" do
      other_room_member = create(:room_member)

      expect {
        delete "/api/rooms/#{other_room_member.room_id}", headers: headers
      }.not_to change(Room, :count)

      expect(response).to have_http_status(:not_found)
    end

    it "returns unauthorized without a token" do
      room_member = create(:room_member, user: user)

      delete "/api/rooms/#{room_member.room_id}"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/rooms/:id" do
    let(:owner) { create(:user) }
    let(:headers) { { "Authorization" => "Bearer #{JsonWebToken.encode(user_id: owner.id)}" } }
    let(:room) { create(:room, owner: owner) }
    let!(:owner_member) { create(:room_member, room: room, user: owner, partner_display_name: "つま") }
    let(:partner) { create(:user) }
    let!(:partner_member) { create(:room_member, room: room, user: partner, partner_display_name: "おっと") }

    it "updates the display name the current user gave their partner" do
      patch "/api/rooms/#{room.id}", params: { room: { partner_display_name: "おかあさん" } }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["partner_display_name"]).to eq("おかあさん")
      expect(owner_member.reload.partner_display_name).to eq("おかあさん")
    end

    it "leaves the name the partner gave untouched" do
      patch "/api/rooms/#{room.id}", params: { room: { partner_display_name: "おかあさん" } }, headers: headers

      expect(partner_member.reload.partner_display_name).to eq("おっと")
    end

    it "returns unprocessable_entity with a blank name" do
      patch "/api/rooms/#{room.id}", params: { room: { partner_display_name: "" } }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(owner_member.reload.partner_display_name).to eq("つま")
    end

    it "returns not_found for a room the current user is not a member of, leaving it untouched" do
      other_owner = create(:user)
      other_room = create(:room, owner: other_owner)
      other_member = create(:room_member, room: other_room, user: other_owner, partner_display_name: "ほかのひと")

      patch "/api/rooms/#{other_room.id}", params: { room: { partner_display_name: "だれか" } }, headers: headers

      expect(response).to have_http_status(:not_found)
      expect(other_member.reload.partner_display_name).to eq("ほかのひと")
    end

    it "returns unauthorized without a token" do
      patch "/api/rooms/#{room.id}", params: { room: { partner_display_name: "おかあさん" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
