require "rails_helper"

RSpec.describe "Api::Invitations", type: :request do
  let(:owner) { create(:user) }
  let(:owner_token) { JsonWebToken.encode(user_id: owner.id) }
  let(:owner_headers) { { "Authorization" => "Bearer #{owner_token}" } }
  let(:room) { create(:room, owner: owner) }
  let(:room_member) { create(:room_member, room: room, user: owner, partner_display_name: "妻") }

  describe "GET /api/invitations/:token" do
    it "returns the room id and inviter nickname" do
      invitation = create(:invitation, room: room)

      get "/api/invitations/#{invitation.token}"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        { "room_id" => room.id, "inviter_nickname" => owner.nickname }
      )
    end

    it "returns not_found for a non-existent token" do
      get "/api/invitations/invalid-token"

      expect(response).to have_http_status(:not_found)
    end

    it "returns gone for an expired invitation" do
      invitation = create(:invitation, room: room, expires_at: 1.day.ago)

      get "/api/invitations/#{invitation.token}"

      expect(response).to have_http_status(:gone)
    end
  end

  describe "POST /api/rooms/:room_id/invitations" do
    it "creates an invitation for a room the current user owns" do
      room_member

      expect {
        post "/api/rooms/#{room.id}/invitations", headers: owner_headers
      }.to change(Invitation, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["token"]).to be_present
    end

    it "returns not_found for a room the current user is not a member of" do
      other_room = create(:room)

      post "/api/rooms/#{other_room.id}/invitations", headers: owner_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns unauthorized without a token" do
      room_member

      post "/api/rooms/#{room.id}/invitations"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/invitations/:token/join" do
    let(:joiner) { create(:user) }
    let(:joiner_token) { JsonWebToken.encode(user_id: joiner.id) }
    let(:joiner_headers) { { "Authorization" => "Bearer #{joiner_token}" } }

    it "creates a room_member for the joining user" do
      invitation = create(:invitation, room: room)
      room_member

      expect {
        post "/api/invitations/#{invitation.token}/join",
          params: { invitation: { partner_display_name: "夫" } },
          headers: joiner_headers
      }.to change(RoomMember, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)).to eq({ "room_id" => room.id })
      expect(room.room_members.find_by(user: joiner).partner_display_name).to eq("夫")
    end

    it "returns unprocessable_entity with a blank partner_display_name" do
      invitation = create(:invitation, room: room)
      room_member

      expect {
        post "/api/invitations/#{invitation.token}/join",
          params: { invitation: { partner_display_name: "" } },
          headers: joiner_headers
      }.not_to change(RoomMember, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to be_present
    end

    it "returns unprocessable_entity when the user already joined the room" do
      invitation = create(:invitation, room: room)
      room_member
      create(:room_member, room: room, user: joiner, partner_display_name: "夫")

      expect {
        post "/api/invitations/#{invitation.token}/join",
          params: { invitation: { partner_display_name: "夫" } },
          headers: joiner_headers
      }.not_to change(RoomMember, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include("すでにこのルームに参加しています")
    end

    it "returns not_found for a non-existent token" do
      post "/api/invitations/invalid-token/join",
        params: { invitation: { partner_display_name: "夫" } },
        headers: joiner_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns gone for an expired invitation" do
      invitation = create(:invitation, room: room, expires_at: 1.day.ago)
      room_member

      post "/api/invitations/#{invitation.token}/join",
        params: { invitation: { partner_display_name: "夫" } },
        headers: joiner_headers

      expect(response).to have_http_status(:gone)
    end

    it "returns unauthorized without a token" do
      invitation = create(:invitation, room: room)
      room_member

      post "/api/invitations/#{invitation.token}/join",
        params: { invitation: { partner_display_name: "夫" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
