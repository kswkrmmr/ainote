// navigator.clipboard は非セキュアコンテキストでは存在せず、権限が拒否されると reject する。
// 呼び出し側が結果を扱えるよう、例外にせず成否を返す
export async function copyText(text) {
  try {
    await navigator.clipboard.writeText(text)
    return true
  } catch {
    return false
  }
}
