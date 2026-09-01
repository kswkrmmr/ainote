module Api
  class RoomsController < ApplicationController
    before_action :authenticate_user!

    def index
      room_members = current_user.room_members.includes(room: { room_members: { user: { avatar_attachment: :blob } } })
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
      result = RoomCreator.call(owner: current_user, partner_display_name: room_params[:partner_display_name])

      if result.success?
        render json: { id: result.room.id }, status: :created
      else
        render json: { errors: result.errors }, status: :unprocessable_entity
      end
    end

    def destroy
      room_member = current_user.room_members.find_by(room_id: params[:id])

      if room_member
        room_member.room.destroy
        head :no_content
      else
        render json: { errors: [ "ルームが見つかりません" ] }, status: :not_found
      end
    end

    private

    def room_json(room_member)
      partner = room_member.room.room_members.find { |member| member.user_id != current_user.id }&.user

      {
        id: room_member.room_id,
        partner_display_name: room_member.partner_display_name,
        partner_avatar_url: partner&.avatar&.attached? ? rails_blob_url(partner.avatar, host: request.base_url) : nil,
        awaiting_partner: room_member.room.room_members.size < 2
      }
    end

    def room_params
      params.require(:room).permit(:partner_display_name)
    end
  end
end
