import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import Header from '@/components/Header'
import { Button, buttonVariants } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { getToken, clearToken } from '@/lib/auth'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

function InvitationPage() {
  const { token } = useParams()
  const navigate = useNavigate()
  const [invitation, setInvitation] = useState(null)
  const [error, setError] = useState(null)
  const [partnerDisplayName, setPartnerDisplayName] = useState('')
  const [joinErrors, setJoinErrors] = useState([])
  const [submitting, setSubmitting] = useState(false)

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

  async function handleJoin(event) {
    event.preventDefault()
    setSubmitting(true)
    setJoinErrors([])

    try {
      const response = await fetch(`${apiBaseUrl}/api/invitations/${token}/join`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify({ invitation: { partner_display_name: partnerDisplayName } }),
      })
      const data = await response.json()

      if (!response.ok) {
        if (response.status === 401) {
          clearToken()
          navigate('/login')
          return
        }
        setJoinErrors(data.errors || ['参加に失敗しました'])
        return
      }

      navigate(`/rooms/${data.room_id}`)
    } catch {
      setJoinErrors(['通信エラーが発生しました'])
    } finally {
      setSubmitting(false)
    }
  }

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
          <form onSubmit={handleJoin} className="signup-form">
            <div className="form-field">
              <Label htmlFor="partnerDisplayName">話したい相手の呼び方</Label>
              <Input
                id="partnerDisplayName"
                type="text"
                value={partnerDisplayName}
                onChange={(event) => setPartnerDisplayName(event.target.value)}
                required
              />
              <p className="form-hint">相手には表示されません</p>
            </div>
            {joinErrors.length > 0 && (
              <ul className="form-errors">
                {joinErrors.map((joinError) => (
                  <li key={joinError}>{joinError}</li>
                ))}
              </ul>
            )}
            <Button type="submit" disabled={submitting}>
              {submitting ? '参加中...' : '参加する'}
            </Button>
            <Button type="button" variant="outline" onClick={() => navigate('/rooms')}>
              参加しない
            </Button>
          </form>
        ) : (
          <>
            <p>参加するには、まず新規登録またはログインしてください。</p>
            <Link
              to={`/signup?redirect=${encodeURIComponent(`/invitations/${token}`)}`}
              className={buttonVariants()}
            >
              新規登録
            </Link>
            <Link
              to={`/login?redirect=${encodeURIComponent(`/invitations/${token}`)}`}
              className={buttonVariants({ variant: 'outline' })}
            >
              ログイン
            </Link>
          </>
        )}
      </main>
    </>
  )
}

export default InvitationPage
