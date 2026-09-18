# LINE公式のアカウント連携フローを扱う。
# https://developers.line.biz/en/docs/messaging-api/linking-accounts/
#
# 1. 友だち追加(follow)で、未連携ならlinkToken付きの連携URLをLINEに送る   → send_link_url
# 2. ユーザーがURLを開いてあいのてにログインし、nonceを発行してLINEへ送る → start
# 3. LINEが本人確認をしてaccountLinkイベントを送ってくるので紐づける      → complete
#
# 自前のワンタイムコードではなくこのフローを使うのは、LINE側で「linkTokenの発行先本人か」を
# 検証してくれるため。自前だと攻撃者のLINEを他人のアカウントに紐づけられてしまう。
class LineAccountLinker
  LINK_TTL = 10.minutes
  ACCOUNT_LINK_ENDPOINT = "https://access.line.me/dialog/bot/accountLink".freeze

  class << self
    def send_link_url(line_user_id)
      return if User.exists?(line_user_id: line_user_id)

      link_token = LineClient.issue_link_token(line_user_id)
      LineClient.push_text(line_user_id, link_message(link_token))
    end

    # ログイン済みのユーザーについてnonceを発行し、LINEの連携エンドポイントのURLを返す
    def start(user, link_token)
      LineAccountLink.where(expires_at: ..Time.current).delete_all

      # LINEの要件: 推測できない値・10〜255文字・128bit以上の安全な乱数
      link = user.line_account_links.create!(
        nonce: SecureRandom.urlsafe_base64(24),
        expires_at: LINK_TTL.from_now
      )

      "#{ACCOUNT_LINK_ENDPOINT}?#{URI.encode_www_form(linkToken: link_token, nonce: link.nonce)}"
    end

    def complete(line_user_id, link)
      nonce = link.is_a?(Hash) ? link["nonce"] : nil
      return if nonce.blank?

      account_link = LineAccountLink.find_by(nonce: nonce)
      return unless account_link

      # nonceは結果に関わらず1回限り
      account_link.destroy!
      return unless link["result"] == "ok"
      return if account_link.expires_at.past?

      user = account_link.user
      # 同じLINEアカウントが別のユーザーに紐づいていれば、通知先が混ざるので連携しない
      return if User.where.not(id: user.id).exists?(line_user_id: line_user_id)

      user.update!(line_user_id: line_user_id)
      LineClient.push_text(line_user_id, completed_message)
    end

    # プロフィール画面から解除されたときに、解除したLINEへ知らせる。
    # 解除自体はすでに済んでいるので、送信に失敗しても解除を取り消さない
    def notify_unlinked(line_user_id)
      LineClient.push_text(line_user_id, unlinked_message)
    rescue StandardError => e
      Rails.logger.error("[LINE] failed to notify unlink: #{e.class}: #{e.message}")
    end

    # ブロック(unfollow)されたときは連携も解除する。
    # ブロックしたユーザーにはメッセージを送れないので、解除の通知はしない。
    #
    # ただしLINEログインで作られたアカウントは、連携を外すとログインする手段が
    # 無くなってしまう（メールアドレスもパスワードも持たない）ため対象外にする。
    # 通知は届かなくなるが、アカウントは使い続けられる。
    def unlink(line_user_id)
      User.where(line_user_id: line_user_id).find_each do |user|
        next if user.line_only?

        user.update!(line_user_id: nil)
      end
    end

    private

    def frontend_origin
      Rails.configuration.x.frontend_origin
    end

    def link_message(link_token)
      url = "#{frontend_origin}/line/link?#{URI.encode_www_form(linkToken: link_token)}"

      <<~TEXT.chomp
        友だち追加ありがとうございます。
        あいのてのアカウントと連携すると、お知らせをLINEで受け取れます。
        下のURLから連携してください（10分間有効です）。
        #{url}

        期限が切れた場合は「連携」と送ってください。
      TEXT
    end

    # 連携の最後に表示されるのはLINEの画面で、あいのてへ戻す指定ができないため、ここに戻り先を載せる
    def completed_message
      <<~TEXT.chomp
        あいのてとの連携が完了しました。
        連携はプロフィール画面からいつでも解除できます。
        #{frontend_origin}/profile
      TEXT
    end

    def unlinked_message
      <<~TEXT.chomp
        あいのてとのLINE連携を解除しました。
        心当たりがない場合は、あいのてにログインしてパスワードを変更してください。
        #{frontend_origin}/profile

        もう一度連携するときは「連携」と送ってください。
      TEXT
    end
  end
end
