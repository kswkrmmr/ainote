require "rails_helper"

RSpec.describe JsonWebToken do
  describe ".decode" do
    it "returns the payload of a token it issued" do
      token = described_class.encode(user_id: 42)

      expect(described_class.decode(token)[:user_id]).to eq(42)
    end

    # 期限切れの扱いはjwt gemの例外に依存しているため、gemを上げたときに気づけるようにしておく
    it "returns nil for an expired token" do
      token = described_class.encode({ user_id: 42 }, 1.second.ago)

      expect(described_class.decode(token)).to be_nil
    end

    it "keeps accepting a token until it expires" do
      token = described_class.encode({ user_id: 42 }, 1.hour.from_now)

      expect(described_class.decode(token)).to be_present
    end

    it "returns nil for a malformed token" do
      expect(described_class.decode("not-a-token")).to be_nil
    end

    it "returns nil for a token signed with another key" do
      forged = JWT.encode({ user_id: 42, exp: 1.hour.from_now.to_i }, "another-secret")

      expect(described_class.decode(forged)).to be_nil
    end

    it "returns nil when the payload was tampered with" do
      header, payload, signature = described_class.encode(user_id: 42).split(".")
      tampered_payload = Base64.urlsafe_encode64({ user_id: 99 }.to_json, padding: false)

      expect(described_class.decode([ header, tampered_payload, signature ].join("."))).to be_nil
    end
  end
end
