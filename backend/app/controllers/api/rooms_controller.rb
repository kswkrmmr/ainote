module Api
  class RoomsController < ApplicationController
    before_action :authenticate_user!

    def index
      room_members = current_user.room_members
      render json: room_members.map { |member| room_json(member) }
    end

    def show
      room_member = current_user.room_members.find_by(room_id: params[:id])

      if room_member
        render json: room_json(room_member)
      else
        render json: { errors: [ "ルームが見つかりません" ] }, status: :not_found
      end
    end

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

    def room_json(room_member)
      { id: room_member.room_id, partner_display_name: room_member.partner_display_name }
    end

    def room_params
      params.require(:room).permit(:partner_display_name)
    end
  end
end
