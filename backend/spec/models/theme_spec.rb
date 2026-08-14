require "rails_helper"

RSpec.describe Theme, type: :model do
  it "is valid with valid attributes" do
    theme = build(:theme)

    expect(theme).to be_valid
  end

  it "is invalid without a title" do
    theme = build(:theme, title: nil)

    expect(theme).not_to be_valid
    expect(theme.errors[:title]).to include("can't be blank")
  end

  it "is invalid without a room" do
    theme = build(:theme, room: nil)

    expect(theme).not_to be_valid
  end

  it "is invalid without a user" do
    theme = build(:theme, user: nil)

    expect(theme).not_to be_valid
  end
end
