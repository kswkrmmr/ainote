// ログイン・新規登録のあとに戻す先として許可するパス。
// redirect パラメータに任意の値を入れて外部サイトへ飛ばされないよう、前方一致で限定する
const ALLOWED_REDIRECT_PREFIXES = ['/invitations/', '/line/link']

export function safeRedirect(redirect, fallback = '/rooms') {
  if (redirect && ALLOWED_REDIRECT_PREFIXES.some((prefix) => redirect.startsWith(prefix))) {
    return redirect
  }
  return fallback
}
