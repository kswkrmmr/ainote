module Api
  class InvitationsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_room

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
