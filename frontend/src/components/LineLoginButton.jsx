import { useState } from 'react'
import { apiFetch, readJson } from '@/lib/api'
import { lineButtonClass } from '@/lib/line'

// LINEの認可画面へ送り出すボタン。URLの組み立てはバックエンドが行う
function LineLoginButton({ label, redirect, onError }) {
  const [loading, setLoading] = useState(false)

  async function handleClick() {
    setLoading(true)

    try {
      const path = redirect
        ? `/api/line/login_url?redirect=${encodeURIComponent(redirect)}`
        : '/api/line/login_url'
      const response = await apiFetch(path, { auth: false })
      const data = await readJson(response)

      if (!response.ok) {
        onError(data?.errors || [`LINEログインを開始できませんでした（エラー ${response.status}）`])
        return
      }

      window.location.href = data.authorize_url
    } catch {
      onError(['通信エラーが発生しました'])
    } finally {
      setLoading(false)
    }
  }

  return (
    <button type="button" onClick={handleClick} disabled={loading} className={lineButtonClass}>
      {loading ? '準備中...' : label}
    </button>
  )
}

export default LineLoginButton
