class RoomJoiner
  # ルームは2人で1組。招待URLが転送されても3人目が入れないよう、参加時に定員を確認する
  CAPACITY = 2

  ALREADY_JOINED_ERROR = "すでにこのルームに参加しています".freeze
  ROOM_FULL_ERROR = "このルームにはすでに2人が参加しているため、この招待は使えません".freeze

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

  # 定員の確認と追加の間に別のリクエストが割り込まないよう、ルームの行をロックしてから判定する
  def call
    room.with_lock { join }
  end

  private

  def join
    return Result.new(errors: [ ALREADY_JOINED_ERROR ]) if already_joined?
    return Result.new(errors: [ ROOM_FULL_ERROR ]) if full?

    room_member = room.room_members.build(user: @user, partner_display_name: @partner_display_name)

    if room_member.save
      Result.new(room_member: room_member)
    else
      Result.new(errors: room_member.errors.full_messages)
    end
  end

  def room
    @room ||= @invitation.room
  end

  def already_joined?
    @user.room_members.exists?(room_id: room.id)
  end

  def full?
    room.room_members.count >= CAPACITY
  end
end
