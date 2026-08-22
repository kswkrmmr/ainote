class RoomCreator
  Result = Struct.new(:room, :errors, keyword_init: true) do
    def success?
      errors.nil?
    end
  end

  def self.call(owner:, partner_display_name:)
    new(owner: owner, partner_display_name: partner_display_name).call
  end

  def initialize(owner:, partner_display_name:)
    @owner = owner
    @partner_display_name = partner_display_name
  end

  def call
    room = @owner.owned_rooms.build
    room_member = RoomMember.new(room: room, user: @owner, partner_display_name: @partner_display_name)

    Room.transaction do
      room.save!
      room_member.save!
    end

    Result.new(room: room)
  rescue ActiveRecord::RecordInvalid
    Result.new(errors: room.errors.full_messages + room_member.errors.full_messages)
  end
end
