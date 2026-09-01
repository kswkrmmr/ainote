class User < ApplicationRecord
  has_secure_password

  has_many :owned_rooms, class_name: "Room", foreign_key: :owner_id, dependent: :destroy, inverse_of: :owner
  has_many :room_members, dependent: :destroy
  has_many :themes, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_one_attached :avatar

  AVATAR_CONTENT_TYPES = [ "image/png", "image/jpeg", "image/webp" ].freeze
  AVATAR_MAX_SIZE = 5.megabytes

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :nickname, presence: true
  validates :email, presence: true, uniqueness: true,
  format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :password, confirmation: true
  validate :avatar_format, :avatar_size

  private

  def avatar_format
    return unless avatar.attached?

    unless avatar.content_type.in?(AVATAR_CONTENT_TYPES)
      errors.add(:avatar, "はPNG・JPEG・WebPのいずれかの形式にしてください")
    end
  end

  def avatar_size
    return unless avatar.attached?

    if avatar.byte_size > AVATAR_MAX_SIZE
      errors.add(:avatar, "は5MB以下にしてください")
    end
  end
end
