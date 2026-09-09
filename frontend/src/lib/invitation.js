export function buildInvitationMessage(url) {
  return `「あいのて」で話してみませんか。\n言葉ですれ違わずに、落ち着いて話し合うためのアプリです。\nこのURLから参加してください。\n\n${url}`
}

// LINEの「送信先を選択」画面を開くURL。text はUTF-8のパーセントエンコードが必要。
// 旧来の line://msg/text/... はLINEアプリ内でしか動かないため、公式が案内する
// https 形式を使う。
export function buildLineShareUrl(message) {
  return `https://line.me/R/share?text=${encodeURIComponent(message)}`
}
