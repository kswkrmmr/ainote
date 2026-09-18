import { useEffect, useRef, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import Header from '@/components/Header'
import { buttonVariants } from '@/components/ui/button'
import { setToken } from '@/lib/auth'
import { apiFetch, readJson } from '@/lib/api'
import { safeRedirect } from '@/lib/redirect'

// LINEから戻ってきた時点で分かる失敗。ログインを試すまでもないもの
function failureMessages({ loginError, code, state }) {
  if (loginError === 'access_denied') {
    return ['LINEでのログインをキャンセルしました。']
  }
  if (loginError) {
    return ['LINEでのログインに失敗しました。もう一度お試しください。']
  }
  if (!code || !state) {
    return ['ログインの情報が不足しています。もう一度お試しください。']
  }
  return null
}

// LINEログインのコールバック。認可コードを受け取り、バックエンドでログインを済ませる
function LineCallbackPage() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const [errors, setErrors] = useState([])
  const startedRef = useRef(false)
  const code = searchParams.get('code')
  const state = searchParams.get('state')
  // ユーザーがLINEの画面でキャンセルすると、codeの代わりにerrorが付いて戻ってくる
  const loginError = searchParams.get('error')

  // パラメータ不足やキャンセルは描画時に判断する（エフェクトの中で状態を更新しないため）
  const messages = failureMessages({ loginError, code, state }) || errors

  useEffect(() => {
    // Strictモードで2回実行されると認可コードを二重に使ってしまうため、1回だけ走らせる
    if (startedRef.current) {
      return
    }
    startedRef.current = true

    if (loginError || !code || !state) {
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
  }, [loginError, code, state, navigate])

  return (
    <>
      <Header />
      <main className="signup-page">
        {messages.length > 0 ? (
          <>
            <h1>
              {loginError === 'access_denied'
                ? 'ログインを中止しました'
                : 'LINEでログインできませんでした'}
            </h1>
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
