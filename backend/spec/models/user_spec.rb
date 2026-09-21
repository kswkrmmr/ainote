require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with a valid email and password" do
      user = build(:user)
      expect(user).to be_valid
    end

    it "is invalid without a nickname" do
      user = build(:user, nickname: nil)
      expect(user).not_to be_valid
      expect(user.errors[:nickname]).to include("を入力してください")
    end

    it "is valid without an email or password when the account was created by LINE login" do
      expect(build(:user, :line_only)).to be_valid
    end

    it "never authenticates a LINE-only account, which has no password" do
      user = create(:user, :line_only)

      expect(user.authenticate("password123")).to be(false)
    end

    it "is valid after withdrawal, when it has neither email nor password" do
      user = create(:user)
      user.withdraw!

      expect(user).to be_valid
    end

    it "is invalid without an email" do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("を入力してください")
    end

    it "is invalid with a duplicate email" do
      create(:user, email: "duplicate@example.com")
      user = build(:user, email: "duplicate@example.com")

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("はすでに存在します")
    end

    it "is invalid with a duplicate email regardless of case" do
      create(:user, email: "duplicate@example.com")
      user = build(:user, email: "DUPLICATE@example.com")

      expect(user).not_to be_valid
    end

    it "is invalid with a malformed email" do
      user = build(:user, email: "not-an-email")

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("は不正な値です")
    end

    it "is invalid with a password shorter than 8 characters" do
      user = build(:user, password: "short1")

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("は8文字以上で入力してください")
    end

    it "is valid without a password when the password is not being changed" do
      user = create(:user)
      reloaded_user = User.find(user.id)
      reloaded_user.email = Faker::Internet.unique.email

      expect(reloaded_user).to be_valid
    end
  end

  describe "email normalization" do
    it "strips whitespace and downcases the email before saving" do
      user = create(:user, email: "  Test@Example.com  ")

      expect(user.email).to eq("test@example.com")
    end
  end

  describe "#authenticate" do
    it "returns the user when the password is correct" do
      user = create(:user, password: "password123")

      expect(user.authenticate("password123")).to eq(user)
    end

    it "returns false when the password is incorrect" do
      user = create(:user, password: "password123")

      expect(user.authenticate("wrongpassword")).to eq(false)
    end
  end

  describe "#withdraw!" do
    let(:partner) { create(:user) }
    let(:user) { create(:user, line_user_id: "U_WITHDRAW") }

    it "keeps the conversation but clears the personal information" do
      room = create(:room, owner: user)
      create(:room_member, room: room, user: user, partner_display_name: "あいて")
      create(:room_member, room: room, user: partner, partner_display_name: "本人")
      theme = create(:theme, room: room, user: user)
      message = create(:message, theme: theme, user: user, translated_body: "残るはず")

      user.withdraw!

      expect(Room.exists?(room.id)).to be(true)
      expect(Theme.exists?(theme.id)).to be(true)
      expect(Message.find(message.id).translated_body).to eq("残るはず")
      expect(room.room_members.count).to eq(2)
    end

    it "frees the email so the person can register again" do
      user.update!(email: "again@example.com")

      user.withdraw!

      expect(user.reload.email).to be_nil
      expect(build(:user, email: "again@example.com")).to be_valid
    end

    it "removes the password, the LINE link and the avatar, and renames the account" do
      user.avatar.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/avatar.png")),
        filename: "avatar.png", content_type: "image/png"
      )

      user.withdraw!
      user.reload

      expect(user.password_digest).to be_nil
      expect(user.line_user_id).to be_nil
      expect(user.avatar).not_to be_attached
      expect(user.nickname).to eq("退会したユーザー")
      expect(user).to be_deleted
    end

    it "is excluded from the active scope" do
      user.withdraw!

      expect(User.active).not_to include(user)
    end
  end
end
