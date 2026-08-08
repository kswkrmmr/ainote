class Room < ApplicationRecord
  belongs_to :owner, class_name: "User"

  has_many :room_members, dependent: :destroy
end
