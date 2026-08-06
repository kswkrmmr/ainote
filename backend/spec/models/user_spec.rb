require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with a valid email and password" do
      user = build(:user)
      expect(user).to be_valid
    end

    it "is invalid without an email" do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "is invalid with a duplicate email" do
      create(:user, email: "duplicate@example.com")
      user = build(:user, email: "duplicate@example.com")

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("has already been taken")
    end

    it "is invalid with a duplicate email regardless of case" do
      create(:user, email: "duplicate@example.com")
      user = build(:user, email: "DUPLICATE@example.com")

      expect(user).not_to be_valid
    end

    it "is invalid with a malformed email" do
      user = build(:user, email: "not-an-email")

      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end

    it "is invalid with a password shorter than 8 characters" do
      user = build(:user, password: "short1")

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("is too short (minimum is 8 characters)")
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
end
