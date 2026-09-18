require "rails_helper"

RSpec.describe LineAccountLinker do
  before do
    allow(LineClient).to receive(:issue_link_token).and_return("LINKTOKEN")
    allow(LineClient).to receive(:push_text)
  end

  describe ".send_link_url" do
    it "sends a link URL containing the issued link token to an unlinked LINE user" do
      described_class.send_link_url("U1111")

      expect(LineClient).to have_received(:issue_link_token).with("U1111")
      expect(LineClient).to have_received(:push_text).with("U1111", %r{/line/link\?linkToken=LINKTOKEN})
    end

    it "does nothing when the LINE user is already linked" do
      create(:user, line_user_id: "U1111")

      described_class.send_link_url("U1111")

      expect(LineClient).not_to have_received(:issue_link_token)
      expect(LineClient).not_to have_received(:push_text)
    end
  end

  describe ".start" do
    let(:user) { create(:user) }

    it "saves a single-use nonce and returns the LINE account-link URL" do
      url = described_class.start(user, "LINKTOKEN")

      link = user.line_account_links.last
      query = Rack::Utils.parse_query(URI(url).query)
      expect(url).to start_with("https://access.line.me/dialog/bot/accountLink?")
      expect(query["linkToken"]).to eq("LINKTOKEN")
      expect(query["nonce"]).to eq(link.nonce)
    end

    it "generates a nonce that meets LINE's length requirement and expires in 10 minutes" do
      described_class.start(user, "LINKTOKEN")

      link = user.line_account_links.last
      expect(link.nonce.length).to be_between(10, 255)
      expect(link.expires_at).to be_within(5.seconds).of(10.minutes.from_now)
    end

    it "does not reuse a nonce across attempts" do
      described_class.start(user, "LINKTOKEN")
      described_class.start(user, "LINKTOKEN")

      expect(user.line_account_links.pluck(:nonce).uniq.size).to eq(2)
    end

    it "also clears expired links left behind by other users" do
      stale = create(:line_account_link, user: create(:user), expires_at: 1.minute.ago)

      described_class.start(user, "LINKTOKEN")

      expect(LineAccountLink.exists?(stale.id)).to be(false)
    end

    it "removes the user's expired links but keeps ones still in progress" do
      expired = create(:line_account_link, user: user, expires_at: 1.minute.ago)
      active = create(:line_account_link, user: user)

      described_class.start(user, "LINKTOKEN")

      expect(LineAccountLink.exists?(expired.id)).to be(false)
      expect(LineAccountLink.exists?(active.id)).to be(true)
    end
  end

  describe ".complete" do
    let(:user) { create(:user) }
    let!(:account_link) { create(:line_account_link, user: user) }

    it "links the LINE user, consumes the nonce and tells the user they can unlink" do
      described_class.complete("U1111", { "result" => "ok", "nonce" => account_link.nonce })

      expect(user.reload.line_user_id).to eq("U1111")
      expect(LineAccountLink.exists?(account_link.id)).to be(false)
      expect(LineClient).to have_received(:push_text).with("U1111", /いつでも解除できます/)
    end

    it "includes a link back to the profile page, since LINE's screen cannot return to the app" do
      described_class.complete("U1111", { "result" => "ok", "nonce" => account_link.nonce })

      expect(LineClient).to have_received(:push_text).with("U1111", %r{/profile})
    end

    it "does not link when LINE reports that verification failed, but still consumes the nonce" do
      described_class.complete("U1111", { "result" => "failed", "nonce" => account_link.nonce })

      expect(user.reload.line_user_id).to be_nil
      expect(LineAccountLink.exists?(account_link.id)).to be(false)
    end

    it "does not link with an expired nonce" do
      account_link.update!(expires_at: 1.minute.ago)

      described_class.complete("U1111", { "result" => "ok", "nonce" => account_link.nonce })

      expect(user.reload.line_user_id).to be_nil
    end

    it "does nothing for an unknown nonce" do
      described_class.complete("U1111", { "result" => "ok", "nonce" => "unknown-nonce" })

      expect(user.reload.line_user_id).to be_nil
      expect(LineAccountLink.exists?(account_link.id)).to be(true)
    end

    it "does not link a LINE account that already belongs to another user" do
      other = create(:user, line_user_id: "U1111")

      described_class.complete("U1111", { "result" => "ok", "nonce" => account_link.nonce })

      expect(user.reload.line_user_id).to be_nil
      expect(other.reload.line_user_id).to eq("U1111")
    end

    it "ignores an event without link information" do
      expect { described_class.complete("U1111", nil) }.not_to raise_error
      expect(user.reload.line_user_id).to be_nil
    end
  end

  describe ".unlink" do
    it "clears the LINE user id of the linked user" do
      user = create(:user, line_user_id: "U1111")

      described_class.unlink("U1111")

      expect(user.reload.line_user_id).to be_nil
    end

    it "keeps the link for an account created by LINE login, which would otherwise lose its only way in" do
      user = create(:user, :line_only)

      described_class.unlink(user.line_user_id)

      expect(user.reload.line_user_id).to be_present
      expect(user.email).to be_nil
      expect(user.password_digest).to be_nil
    end

    it "does not message a user who blocked the account" do
      create(:user, line_user_id: "U1111")

      described_class.unlink("U1111")

      expect(LineClient).not_to have_received(:push_text)
    end
  end

  describe ".notify_unlinked" do
    it "tells the LINE user that linking was removed and what to do if it was not them" do
      described_class.notify_unlinked("U1111")

      expect(LineClient).to have_received(:push_text).with("U1111", /解除しました.*心当たりがない場合/m)
    end

    it "does not raise when LINE cannot deliver the message" do
      allow(LineClient).to receive(:push_text).and_raise(LineClient::Error, "boom")

      expect { described_class.notify_unlinked("U1111") }.not_to raise_error
    end
  end
end
