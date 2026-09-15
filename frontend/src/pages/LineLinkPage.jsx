import { useEffect, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import Header from '@/components/Header'
import { Button, buttonVariants } from '@/components/ui/button'
import { getToken } from '@/lib/auth'
import { useApi, readJson } from '@/lib/api'

// LINEに届いた連携URLの開き先。ログインしてから、LINEの連携エンドポイントへ送り出す
function LineLinkPage() {
  const navigate = useNavigate()
  const api = useApi()
  const [searchParams] = useSearchParams()
  const linkToken = searchParams.get('linkToken')
  const loggedIn = Boolean(getToken())
  const [linked, setLinked] = useState(null)
  const [errors, setErrors] = useState([])
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    if (linkToken && !loggedIn) {
      const back = `/line/link?linkToken=${encodeURIComponent(linkToken)}`
      navigate(`/login?redirect=${encodeURIComponent(back)}`, { replace: true })
    }
  }, [linkToken, loggedIn, navigate])

  useEffect(() => {
    if (!linkToken || !loggedIn) {
      return
    }

    let cancelled = false

    function loadLinkStatus() {
      api('/api/me')
        .then((response) => (response?.ok ? response.json() : null))
        .then((data) => {
          if (!cancelled && data) {
            setLinked(data.line_linked)
          }
        })
    }

    loadLinkStatus()

    // 連携後にLINEの画面からブラウザの「戻る」で戻ると、このページがキャッシュから
    // 復元されて連携前の表示のまま残ることがあるため、状態を取り直す
    function handlePageShow(event) {
      if (event.persisted) {
        loadLinkStatus()
      }
    }

    window.addEventListener('pageshow', handlePageShow)

    return () => {
      cancelled = true
      window.removeEventListener('pageshow', handlePageShow)
    }
  }, [api, linkToken, loggedIn])

  async function handleLink() {
    setSubmitting(true)
    setErrors([])

    try {
      const response = await api('/api/line/account_link', {
        method: 'POST',
        body: { link_token: linkToken },
      })
      if (!response) return

      const data = await readJson(response)

      if (!response.ok) {
        setErrors(data?.errors || [`連携に失敗しました（エラー ${response.status}）`])
        return
      }

      // LINE側で本人確認が行われ、完了するとLINEにお知らせが届く
      window.location.href = data.redirect_url
    } catch {
      setErrors(['通信エラーが発生しました'])
    } finally {
      setSubmitting(false)
    }
  }

  if (!linkToken) {
    return (
      <>
        <Header />
        <main className="signup-page">
          <h1>連携用の情報が見つかりません</h1>
          <p>LINEに届いたメッセージのURLから、もう一度開いてください。</p>
          <Link to="/profile" className={buttonVariants()}>
            プロフィールへ
          </Link>
        </main>
      </>
    )
  }

  if (!loggedIn) {
    return null
  }

  if (linked === null) {
    return (
      <>
        <Header />
        <main className="signup-page">
          <h1>連携状況を確認しています</h1>
        </main>
      </>
    )
  }

  if (linked) {
    return (
      <>
        <Header />
        <main className="signup-page">
          <h1>LINEと連携済みです</h1>
          <p className="line-link-description">
            このアカウントはすでにLINEと連携しています。
            <br />
            連携の解除はプロフィール画面からできます。
          </p>
          <Link to="/profile" className={buttonVariants()}>
            プロフィールへ
          </Link>
        </main>
      </>
    )
  }

  return (
    <>
      <Header />
      <main className="signup-page">
        <h1>LINEと連携する</h1>
        <p className="line-link-description">
          あいのてのアカウントとLINEを連携すると、お知らせをLINEで受け取れるようになります。
          <br />
          連携はプロフィール画面からいつでも解除できます。
        </p>
        <p className="form-hint">
          「連携する」を押すとLINEの確認画面に移ります。
          <br />
          連携が終わると、LINEにお知らせが届きます。
        </p>
        {errors.length > 0 && (
          <ul className="form-errors">
            {errors.map((error) => (
              <li key={error}>{error}</li>
            ))}
          </ul>
        )}
        <Button onClick={handleLink} disabled={submitting}>
          {submitting ? '連携中...' : '連携する'}
        </Button>
      </main>
    </>
  )
}

export default LineLinkPage
