FactoryBot.define do
  factory :user do
    nickname { Faker::Internet.unique.username(specifier: 5..10) }
    email { Faker::Internet.unique.email }
    password { "password123" }

    # LINEログインだけで作られたアカウント。メールアドレスもパスワードも持たない
    trait :line_only do
      email { nil }
      password { nil }
      line_user_id { "U#{SecureRandom.hex(16)}" }
    end
  end
end
