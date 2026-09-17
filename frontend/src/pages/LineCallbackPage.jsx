import { useEffect, useRef, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import Header from '@/components/Header'
import { buttonVariants } from '@/components/ui/button'
import { setToken } from '@/lib/auth'
import { apiFetch, readJson } from '@/lib/api'
import { safeRedirect } from '@/lib/redirect'

// LINEログインのコールバック。認可コードを受け取り、バックエンドでログインを済ませる
function LineCallbackPage() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const [errors, setErrors] = useState([])
  const startedRef = useRef(false)
  const code = searchParams.get('code')
  const state = searchParams.get('state')

  // パラメータ不足は描画時に判断する（エフェクトの中で状態を更新しないため）
  const messages =
    !code || !state ? ['ログインの情報が不足しています。もう一度お試しください。'] : errors

  useEffect(() => {
    // Strictモードで2回実行されると認可コードを二重に使ってしまうため、1回だけ走らせる
    if (startedRef.current) {
      return
    }
    startedRef.current = true

    if (!code || !state) {
      return
    }

    apiFetch('/api/line/login', { method: 'POST', auth: false, body: { code, state } })
      .then(async (response) => {
        const data = await readJson(response)

        if (!response.ok) {
          setErrors(data?.errors || [`ログインに失敗しました（エラー ${response.status}）`])
          return
        }

        setToken(data.token)
        navigate(safeRedirect(data.redirect), { replace: true })
      })
      .catch(() => setErrors(['通信エラーが発生しました']))
  }, [code, state, navigate])

  return (
    <>
      <Header />
      <main className="signup-page">
        {messages.length > 0 ? (
          <>
            <h1>LINEでログインできませんでした</h1>
            <ul className="form-errors">
              {messages.map((error) => (
                <li key={error}>{error}</li>
              ))}
            </ul>
            <Link to="/login" className={buttonVariants()}>
              ログイン画面へ
            </Link>
          </>
        ) : (
          <h1>ログインしています</h1>
        )}
      </main>
    </>
  )
}

export default LineCallbackPage
