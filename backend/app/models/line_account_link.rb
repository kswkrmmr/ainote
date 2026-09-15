# LINEのアカウント連携手続き中に発行するnonceを一時保存する。
# accountLinkイベントで受け取ったnonceから、どのユーザーの手続きかを引くために使う。
class LineAccountLink < ApplicationRecord
  belongs_to :user

  validates :nonce, presence: true, uniqueness: true
  validates :expires_at, presence: true
end
