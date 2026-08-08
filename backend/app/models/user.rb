class User < ApplicationRecord
  has_secure_password

  has_many :owned_rooms, class_name: "Room", foreign_key: :owner_id, dependent: :destroy, inverse_of: :owner
  has_many :room_members, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :nickname, presence: true
  validates :email, presence: true, uniqueness: true,
  format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :password, confirmation: true
end
