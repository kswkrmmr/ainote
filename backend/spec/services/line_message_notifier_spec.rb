require "rails_helper"

RSpec.describe LineMessageNotifier do
  let(:sender) { create(:user) }
  let(:recipient) { create(:user, line_user_id: "U_RECIPIENT") }
  let(:room) { create(:room, owner: sender) }
  let!(:sender_member) { create(:room_member, room: room, user: sender, partner_display_name: "おかあさん") }
  # 受け取る人は送り主を「たろう」と呼んでいる
  let!(:recipient_member) { create(:room_member, room: room, user: recipient, partner_display_name: "たろう") }
  let(:theme) { create(:theme, room: room, user: sender, title: "離婚について") }

  before { allow(LineClient).to receive(:push_text) }

  def send_message(from: sender, in_theme: theme)
    described_class.notify(create(:message, theme: in_theme, user: from, translated_body: "本文です"))
  end

  it "notifies the recipient, naming the sender the way the recipient calls them, with a link to the theme" do
    send_message

    expect(LineClient).to have_received(:push_text).with("U_RECIPIENT", /たろうから/)
    expect(LineClient).to have_received(:push_text).with("U_RECIPIENT", %r{/themes/#{theme.id}})
  end

  it "does not put the message body or the theme title in the notification" do
    send_message

    expect(LineClient).to have_received(:push_text) do |_line_user_id, text|
      expect(text).not_to include("本文です")
      expect(text).not_to include("離婚について")
    end
  end

  it "does not notify the sender" do
    sender.update!(line_user_id: "U_SENDER")

    send_message

    expect(LineClient).not_to have_received(:push_text).with("U_SENDER", anything)
  end

  it "does nothing when the recipient has not linked LINE" do
    recipient.update!(line_user_id: nil)

    send_message

    expect(LineClient).not_to have_received(:push_text)
    expect(recipient_member.reload.line_notified_at).to be_nil
  end

  it "does nothing while the partner has not joined the room yet" do
    recipient_member.destroy!

    expect { send_message }.not_to raise_error
    expect(LineClient).not_to have_received(:push_text)
  end

  it "records when the recipient was notified" do
    send_message

    expect(recipient_member.reload.line_notified_at).to be_within(5.seconds).of(Time.current)
  end

  describe "notification interval" do
    it "does not notify again within an hour of the last notification" do
      recipient_member.update!(line_notified_at: 59.minutes.ago)

      send_message

      expect(LineClient).not_to have_received(:push_text)
    end

    it "notifies again once an hour has passed" do
      recipient_member.update!(line_notified_at: 61.minutes.ago)

      send_message

      expect(LineClient).to have_received(:push_text).with("U_RECIPIENT", anything)
    end

    it "counts per room, so a message in another theme of the same room is not notified again" do
      other_theme = create(:theme, room: room, user: sender, title: "週末の予定")

      send_message
      send_message(in_theme: other_theme)

      expect(LineClient).to have_received(:push_text).once
    end

    it "still notifies a reply right after the recipient's own message, since they may be waiting for it" do
      sender.update!(line_user_id: "U_SENDER")

      send_message(from: recipient)
      send_message(from: sender)

      expect(LineClient).to have_received(:push_text).with("U_RECIPIENT", anything)
    end
  end

  describe "when LINE cannot deliver" do
    before { allow(LineClient).to receive(:push_text).and_raise(LineClient::Error, "boom") }

    it "does not raise" do
      expect { send_message }.not_to raise_error
    end

    it "clears the record so the next message can notify" do
      send_message
      allow(LineClient).to receive(:push_text)

      send_message

      # 1回目は失敗、記録を戻したので2回目も送られる
      expect(LineClient).to have_received(:push_text).with("U_RECIPIENT", anything).twice
    end
  end
end
