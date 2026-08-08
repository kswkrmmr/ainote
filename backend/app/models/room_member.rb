class RoomMember < ApplicationRecord
  belongs_to :room
  belongs_to :user

  validates :partner_display_name, presence: true
  validates :user_id, uniqueness: { scope: :room_id }
end
