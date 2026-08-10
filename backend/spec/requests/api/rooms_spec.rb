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
        [ { "id" => my_room_member.room_id, "partner_display_name" => "妻" } ]
      )
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
        { "id" => room_member.room_id, "partner_display_name" => "父" }
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
end
