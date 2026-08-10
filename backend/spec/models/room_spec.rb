require "rails_helper"

RSpec.describe Room, type: :model do
  it "is valid with an owner" do
    room = build(:room)

    expect(room).to be_valid
  end

  it "is invalid without an owner" do
    room = build(:room, owner: nil)

    expect(room).not_to be_valid
  end
end
