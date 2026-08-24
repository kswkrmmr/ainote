require "rails_helper"

RSpec.describe Invitation, type: :model do
  it "is valid with a room" do
    invitation = build(:invitation)

    expect(invitation).to be_valid
  end

  it "is invalid without a room" do
    invitation = build(:invitation, room: nil)

    expect(invitation).not_to be_valid
  end

  it "generates a token on creation" do
    invitation = create(:invitation)

    expect(invitation.token).to be_present
  end

  it "does not overwrite an explicitly set token" do
    invitation = create(:invitation, token: "custom-token")

    expect(invitation.token).to eq("custom-token")
  end

  it "is invalid with a duplicate token" do
    existing = create(:invitation)
    duplicate = build(:invitation, token: existing.token)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:token]).to include("はすでに存在します")
  end

  it "sets expires_at to 7 days from now by default" do
    invitation = create(:invitation)

    expect(invitation.expires_at).to be_within(1.minute).of(7.days.from_now)
  end

  it "does not overwrite an explicitly set expires_at" do
    invitation = create(:invitation, expires_at: 1.day.from_now)

    expect(invitation.expires_at).to be_within(1.minute).of(1.day.from_now)
  end
end
