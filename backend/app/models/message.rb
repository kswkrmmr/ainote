class Message < ApplicationRecord
  belongs_to :theme
  belongs_to :user

  validates :original_body, presence: true
  validates :translated_body, presence: true
end
