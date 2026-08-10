class Invitation < ApplicationRecord
  belongs_to :room

  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create
  before_validation :set_expires_at, on: :create

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expires_at
    self.expires_at ||= 7.days.from_now
  end
end
