class RoomJoiner
  ALREADY_JOINED_ERROR = "すでにこのルームに参加しています".freeze

  Result = Struct.new(:room_member, :errors, keyword_init: true) do
    def success?
      errors.nil?
    end
  end

  def self.call(invitation:, user:, partner_display_name:)
    new(invitation: invitation, user: user, partner_display_name: partner_display_name).call
  end

  def initialize(invitation:, user:, partner_display_name:)
    @invitation = invitation
    @user = user
    @partner_display_name = partner_display_name
  end

  def call
    return Result.new(errors: [ ALREADY_JOINED_ERROR ]) if already_joined?

    room_member = @invitation.room.room_members.build(user: @user, partner_display_name: @partner_display_name)

    if room_member.save
      Result.new(room_member: room_member)
    else
      Result.new(errors: room_member.errors.full_messages)
    end
  end

  private

  def already_joined?
    @user.room_members.exists?(room_id: @invitation.room_id)
  end
end
