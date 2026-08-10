FactoryBot.define do
  factory :room do
    owner factory: :user
  end
end
