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

  DELETED_NICKNAME = "退会したユーザー".freeze

  AVATAR_CONTENT_TYPES = [ "image/png", "image/jpeg", "image/webp" ].freeze
  AVATAR_MAX_SIZE = 5.megabytes

  normalizes :email, with: ->(email) { email.strip.downcase }

  scope :active, -> { where(deleted_at: nil) }

  validates :nickname, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, unless: :credentials_optional?
  validates :email, uniqueness: true, allow_nil: true
  validates :password_digest, presence: true, unless: :credentials_optional?
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :password, confirmation: true
  validates :line_user_id, uniqueness: true, allow_nil: true
  validate :avatar_format, :avatar_size

  # LINEログインだけで作られたアカウント。メールアドレスとパスワードを持たない
  def line_only?
    line_user_id.present? && email.blank?
  end

  def deleted?
    deleted_at.present?
  end

  # 退会。メッセージは相手の記録でもあるので消さず、本人の情報だけを消して印を付ける。
  # メールアドレスを空けるのは、同じアドレスで登録し直せるようにするため。
  def withdraw!
    transaction do
      avatar.purge if avatar.attached?

      update!(
        deleted_at: Time.current,
        nickname: DELETED_NICKNAME,
        email: nil,
        password_digest: nil,
        line_user_id: nil
      )
    end
  end

  # パスワードを持たないアカウントは、パスワードでのログインを常に失敗させる
  def authenticate(password)
    return false if password_digest.blank?

    super
  end

  private

  # メールアドレスとパスワードを持たないのは、LINEログインのアカウントと退会済みのアカウント
  def credentials_optional?
    line_only? || deleted?
  end

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
