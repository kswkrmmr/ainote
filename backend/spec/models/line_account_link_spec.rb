require "rails_helper"

RSpec.describe LineAccountLink, type: :model do
  it "is valid with a user, nonce and expiry" do
    expect(build(:line_account_link)).to be_valid
  end

  it "requires a nonce" do
    expect(build(:line_account_link, nonce: nil)).not_to be_valid
  end

  it "requires an expiry" do
    expect(build(:line_account_link, expires_at: nil)).not_to be_valid
  end

  it "does not allow the same nonce twice" do
    existing = create(:line_account_link)

    expect(build(:line_account_link, nonce: existing.nonce)).not_to be_valid
  end
end
