require "net/http"

# LINEログイン（OAuth 2.0 / OpenID Connect）。
# ここで作られるアカウントはLINEログイン専用で、メールアドレスとパスワードを持たない。
# https://developers.line.biz/en/docs/line-login/integrate-line-login/
class LineLogin
  AUTHORIZE_ENDPOINT = "https://access.line.me/oauth2/v2.1/authorize".freeze
  TOKEN_ENDPOINT = "https://api.line.me/oauth2/v2.1/token".freeze
  VERIFY_ENDPOINT = "https://api.line.me/oauth2/v2.1/verify".freeze

  STATE_TTL = 10.minutes
  # ログイン後に戻す先。任意のURLを渡されて外部に飛ばされないよう前方一致で限定する。
  # フロント側にも同じ一覧があるので、増やすときは frontend/src/lib/redirect.js も直すこと
  ALLOWED_REDIRECT_PREFIXES = [ "/invitations/", "/line/link" ].freeze
  DEFAULT_NICKNAME = "LINEユーザー".freeze

  class Error < StandardError; end

  class << self
    def authorize_url(redirect: nil)
      # nonce は state に載せて署名しておき、コールバックでIDトークンの検証に使う。
      # これで「自分が始めたログインのIDトークンか」を確認できる
      nonce = SecureRandom.urlsafe_base64(24)

      query = {
        response_type: "code",
        client_id: channel_id,
        redirect_uri: callback_url,
        state: encode_state(nonce: nonce, redirect: safe_redirect(redirect)),
        scope: "profile openid",
        nonce: nonce,
        # ログインのついでに公式アカウントの友だち追加を促す（通知を受け取れるようにするため）
        bot_prompt: "aggressive"
      }

      "#{AUTHORIZE_ENDPOINT}?#{URI.encode_www_form(query)}"
    end

    def sign_in(code:, state:)
      payload = decode_state(state)
      id_token = exchange_code(code)["id_token"]
      raise Error, "IDトークンが返ってきませんでした" if id_token.blank?

      profile = verify_id_token(id_token, payload["nonce"])
      { user: find_or_create_user(profile), redirect: safe_redirect(payload["redirect"]) }
    end

    private

    def channel_id
      ENV.fetch("LINE_LOGIN_CHANNEL_ID")
    end

    def channel_secret
      ENV.fetch("LINE_LOGIN_CHANNEL_SECRET")
    end

    def callback_url
      "#{Rails.configuration.x.frontend_origin}/line/callback"
    end

    def verifier
      Rails.application.message_verifier(:line_login)
    end

    def encode_state(nonce:, redirect:)
      verifier.generate({ "nonce" => nonce, "redirect" => redirect }, expires_in: STATE_TTL)
    end

    # 署名が合わない・期限切れの state は、こちらが始めたログインではないので弾く
    def decode_state(state)
      verifier.verified(state.to_s) || raise(Error, "ログインの有効期限が切れました。もう一度お試しください。")
    end

    def safe_redirect(redirect)
      return nil if redirect.blank?

      ALLOWED_REDIRECT_PREFIXES.any? { |prefix| redirect.start_with?(prefix) } ? redirect : nil
    end

    def exchange_code(code)
      post_form(TOKEN_ENDPOINT, {
        grant_type: "authorization_code",
        code: code,
        redirect_uri: callback_url,
        client_id: channel_id,
        client_secret: channel_secret
      })
    end

    # IDトークンの検証はLINEのエンドポイントに任せる。nonce も一緒に渡して突き合わせてもらう
    def verify_id_token(id_token, nonce)
      post_form(VERIFY_ENDPOINT, { id_token: id_token, client_id: channel_id, nonce: nonce })
    end

    def post_form(endpoint, params)
      uri = URI(endpoint)
      response = Net::HTTP.post_form(uri, params)
      raise Error, "LINEログインの処理に失敗しました (#{response.code})" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end

    def find_or_create_user(profile)
      line_user_id = profile["sub"]
      raise Error, "LINEのユーザーIDを取得できませんでした" if line_user_id.blank?

      User.active.find_by(line_user_id: line_user_id) ||
        User.create!(line_user_id: line_user_id, nickname: profile["name"].presence || DEFAULT_NICKNAME)
    end
  end
end
