class User < ApplicationRecord
  # LINEログインで作られたアカウントはパスワードを持たないため、
  # has_secure_password の必須チェックは使わず、下で条件付きに書く
  has_secure_password validations: false

  has_many :owned_rooms, class_name: "Room", foreign_key: :owner_id, dependent: :destroy, inverse_of: :owner
  has_many :room_members, dependent: :destroy
  has_many :themes, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :line_account_links, dependent: :delete_all
  has_one_attached :avatar

  AVATAR_CONTENT_TYPES = [ "image/png", "image/jpeg", "image/webp" ].freeze
  AVATAR_MAX_SIZE = 5.megabytes

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :nickname, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, unless: :line_only?
  validates :email, uniqueness: true, allow_nil: true
  validates :password_digest, presence: true, unless: :line_only?
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :password, confirmation: true
  validates :line_user_id, uniqueness: true, allow_nil: true
  validate :avatar_format, :avatar_size

  # LINEログインだけで作られたアカウント。メールアドレスとパスワードを持たない
  def line_only?
    line_user_id.present? && email.blank?
  end

  # パスワードを持たないアカウントは、パスワードでのログインを常に失敗させる
  def authenticate(password)
    return false if password_digest.blank?

    super
  end

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
