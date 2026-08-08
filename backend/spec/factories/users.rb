FactoryBot.define do
  factory :user do
    nickname { Faker::Internet.unique.username(specifier: 5..10) }
    email { Faker::Internet.unique.email }
    password { "password123" }
  end
end
