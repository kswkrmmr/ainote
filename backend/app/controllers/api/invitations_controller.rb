module Api
  class InvitationsController < ApplicationController
    before_action :authenticate_user!, only: [ :create ]
    before_action :set_room, only: [ :create ]

    def show
      invitation = Invitation.find_by(token: params[:token])

      if invitation.nil?
        render json: { errors: [ "招待が見つかりません" ] }, status: :not_found
      elsif invitation.expires_at.present? && invitation.expires_at < Time.current
        render json: { errors: [ "この招待は有効期限が切れています" ] }, status: :gone
      else
        render json: { room_id: invitation.room_id, inviter_nickname: invitation.room.owner.nickname }
      end
    end

    def create
      invitation = @room.invitations.build

      if invitation.save
        render json: { token: invitation.token, expires_at: invitation.expires_at }, status: :created
      else
        render json: { errors: invitation.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def set_room
      room_member = current_user.room_members.find_by(room_id: params[:room_id])

      if room_member
        @room = room_member.room
      else
        render json: { errors: [ "ルームが見つかりません" ] }, status: :not_found
      end
    end
  end
end
