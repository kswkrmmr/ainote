module Api
  class InvitationsController < ApplicationController
    before_action :authenticate_user!, only: [ :create, :join ]
    before_action :set_room, only: [ :create ]
    before_action :set_invitation, only: [ :join ]

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

    def join
      return if performed?

      if current_user.room_members.exists?(room_id: @invitation.room_id)
        render json: { errors: [ "すでにこのルームに参加しています" ] }, status: :unprocessable_entity
        return
      end

      room_member = @invitation.room.room_members.build(user: current_user, partner_display_name: join_params[:partner_display_name])

      if room_member.save
        render json: { room_id: room_member.room_id }, status: :created
      else
        render json: { errors: room_member.errors.full_messages }, status: :unprocessable_entity
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

    def set_invitation
      @invitation = Invitation.find_by(token: params[:token])

      if @invitation.nil?
        render json: { errors: [ "招待が見つかりません" ] }, status: :not_found
      elsif @invitation.expires_at.present? && @invitation.expires_at < Time.current
        render json: { errors: [ "この招待は有効期限が切れています" ] }, status: :gone
      end
    end

    def join_params
      params.require(:invitation).permit(:partner_display_name)
    end
  end
end
