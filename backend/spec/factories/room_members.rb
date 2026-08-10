FactoryBot.define do
  factory :room_member do
    room
    user
    partner_display_name { "妻" }
  end
end
