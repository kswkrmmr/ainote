require "rails_helper"

RSpec.describe RoomMember, type: :model do
  it "is valid with valid attributes" do
    room_member = build(:room_member)

    expect(room_member).to be_valid
  end

  it "is invalid without a partner_display_name" do
    room_member = build(:room_member, partner_display_name: nil)

    expect(room_member).not_to be_valid
    expect(room_member.errors[:partner_display_name]).to include("を入力してください")
  end

  it "is invalid without a room" do
    room_member = build(:room_member, room: nil)

    expect(room_member).not_to be_valid
  end

  it "is invalid without a user" do
    room_member = build(:room_member, user: nil)

    expect(room_member).not_to be_valid
  end

  it "is invalid when the user is already a member of the room" do
    room = create(:room)
    user = create(:user)
    create(:room_member, room: room, user: user)
    duplicate = build(:room_member, room: room, user: user)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to include("はすでに存在します")
  end

  it "is valid when the same user joins a different room" do
    user = create(:user)
    create(:room_member, user: user)
    room_member = build(:room_member, user: user)

    expect(room_member).to be_valid
  end
end
