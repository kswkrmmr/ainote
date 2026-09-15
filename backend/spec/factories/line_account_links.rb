FactoryBot.define do
  factory :line_account_link do
    user
    nonce { SecureRandom.urlsafe_base64(24) }
    expires_at { 10.minutes.from_now }
  end
end
