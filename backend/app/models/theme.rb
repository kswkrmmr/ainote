class Theme < ApplicationRecord
  belongs_to :room
  belongs_to :user

  has_many :messages, dependent: :destroy

  validates :title, presence: true
end
