module Api
  class RoomsController < ApplicationController
    before_action :authenticate_user!

    def create
      room = current_user.owned_rooms.build
      room_member = RoomMember.new(room: room, user: current_user, partner_display_name: room_params[:partner_display_name])

      Room.transaction do
        room.save!
        room_member.save!
      end

      render json: { id: room.id }, status: :created
    rescue ActiveRecord::RecordInvalid
      render json: { errors: room.errors.full_messages + room_member.errors.full_messages }, status: :unprocessable_entity
    end

    private

    def room_params
      params.require(:room).permit(:partner_display_name)
    end
  end
end
