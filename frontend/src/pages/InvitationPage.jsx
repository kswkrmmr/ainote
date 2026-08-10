import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import Header from '@/components/Header'
import { buttonVariants } from '@/components/ui/button'
import { getToken } from '@/lib/auth'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

function InvitationPage() {
  const { token } = useParams()
  const [invitation, setInvitation] = useState(null)
  const [error, setError] = useState(null)

  useEffect(() => {
    fetch(`${apiBaseUrl}/api/invitations/${token}`)
      .then(async (response) => {
        const data = await response.json()
        if (response.ok) {
          setInvitation(data)
        } else {
          setError(data.errors?.[0] || '招待の確認に失敗しました')
        }
      })
      .catch(() => setError('通信エラーが発生しました'))
  }, [token])

  if (error) {
    return (
      <>
        <Header />
        <main className="signup-page">
          <h1>招待を確認できませんでした</h1>
          <p>{error}</p>
          <Link to="/" className={buttonVariants()}>
            トップへ戻る
          </Link>
        </main>
      </>
    )
  }

  if (!invitation) {
    return (
      <>
        <Header />
        <main className="signup-page">
          <h1>招待画面</h1>
        </main>
      </>
    )
  }

  return (
    <>
      <Header />
      <main className="signup-page">
        <h1>招待されています</h1>
        <p>{invitation.inviter_nickname} さんから、あいのてのルームに招待されています。</p>

        {getToken() ? (
          <p>参加する機能は準備中です。</p>
        ) : (
          <>
            <p>参加するには、まず新規登録またはログインしてください。</p>
            <Link to="/signup" className={buttonVariants()}>
              新規登録
            </Link>
            <Link to="/login" className={buttonVariants({ variant: 'outline' })}>
              ログイン
            </Link>
          </>
        )}
      </main>
    </>
  )
}

export default InvitationPage
