# 新しいメッセージが届いたことを、相手のLINEに知らせる。
#
# テンポよくやり取りしている最中に毎回通知が来ると煩わしいので、同じルームでは
# 「受け取る人に最後に通知してから」一定時間は送らない。
# 直前のメッセージを基準にしないのは、自分が送った直後に届いた返信が通知されず、
# 返事を待っている人ほど気づけなくなるため。
class LineMessageNotifier
  # issue #122 では「1時間（仮）」。運用しながら調整する
  NOTIFICATION_INTERVAL = 1.hour

  def self.notify(message)
    new(message).notify
  end

  def initialize(message)
    @message = message
  end

  # 通知に失敗してもメッセージの送信は失敗させないよう、例外はここでログに残して止める
  def notify
    recipient_member = find_recipient_member
    return if recipient_member.nil? || recipient_member.user.line_user_id.blank?

    claim = claim_notification(recipient_member)
    return unless claim

    begin
      LineClient.push_text(recipient_member.user.line_user_id, notification_text(recipient_member))
    rescue StandardError
      # 届けられなかったので、次のメッセージで改めて通知できるよう記録を戻す
      recipient_member.update_column(:line_notified_at, claim[:previous])
      raise
    end
  rescue StandardError => e
    Rails.logger.error("[LINE] failed to notify message #{@message.id}: #{e.class}: #{e.message}")
  end

  private

  # ルームは2人で1組なので、送り主以外のメンバーが受け取る人
  def find_recipient_member
    @message.theme.room.room_members.includes(:user).find { |member| member.user_id != @message.user_id }
  end

  # 同時に2通送られても通知が重複しないよう、行をロックしてから判定と記録を行う。
  # 送ってよければ直前の通知時刻を返し、間隔内なら false を返す
  def claim_notification(recipient_member)
    recipient_member.with_lock do
      previous = recipient_member.line_notified_at
      next false if previous && previous > NOTIFICATION_INTERVAL.ago

      recipient_member.update!(line_notified_at: Time.current)
      { previous: previous }
    end
  end

  # 送り主は、受け取る人がつけた呼び名で表示する。
  # LINEの通知はロック画面にも出るため、メッセージ本文とテーマ名は載せない
  def notification_text(recipient_member)
    <<~TEXT.chomp
      #{recipient_member.partner_display_name}から、あいのてに新しいメッセージが届きました。
      #{Rails.configuration.x.frontend_origin}/themes/#{@message.theme_id}
    TEXT
  end
end
