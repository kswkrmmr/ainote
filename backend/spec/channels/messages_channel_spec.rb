require "rails_helper"

RSpec.describe MessagesChannel, type: :channel do
  let(:user) { create(:user) }
  let(:room) { create(:room, owner: user) }
  let(:theme) { create(:theme, room: room, user: user) }

  before do
    stub_connection(current_user: user)
  end

  it "subscribes and streams for the theme when the user is a room member" do
    create(:room_member, room: room, user: user, partner_display_name: "妻")

    subscribe(theme_id: theme.id)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(theme)
  end

  it "rejects the subscription for a theme the user is not a member of" do
    other_theme = create(:theme)

    subscribe(theme_id: other_theme.id)

    expect(subscription).to be_rejected
  end
end
