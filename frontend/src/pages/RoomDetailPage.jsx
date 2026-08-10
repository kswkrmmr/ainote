import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import Header from '@/components/Header'
import { Button, buttonVariants } from '@/components/ui/button'
import { getToken, clearToken } from '@/lib/auth'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

function RoomDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [room, setRoom] = useState(null)
  const [notFound, setNotFound] = useState(false)
  const [invitationUrl, setInvitationUrl] = useState(null)
  const [issuing, setIssuing] = useState(false)
  const [copied, setCopied] = useState(false)
  const [errors, setErrors] = useState([])

  useEffect(() => {
    const token = getToken()
    if (!token) {
      navigate('/login')
      return
    }

    fetch(`${apiBaseUrl}/api/rooms/${id}`, {
      headers: { Authorization: `Bearer ${token}` },
    })
      .then((response) => {
        if (response.status === 401) {
          clearToken()
          navigate('/login')
          return null
        }
        if (response.status === 404) {
          setNotFound(true)
          return null
        }
        return response.json()
      })
      .then((data) => {
        if (data) {
          setRoom(data)
        }
      })
  }, [id, navigate])

  async function handleIssueInvitation() {
    setIssuing(true)
    setErrors([])
    setCopied(false)

    try {
      const response = await fetch(`${apiBaseUrl}/api/rooms/${id}/invitations`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${getToken()}` },
      })
      const data = await response.json()

      if (response.ok) {
        setInvitationUrl(`${window.location.origin}/invitations/${data.token}`)
      } else if (response.status === 401) {
        clearToken()
        navigate('/login')
      } else {
        setErrors(data.errors || ['招待URLの発行に失敗しました'])
      }
    } catch {
      setErrors(['通信エラーが発生しました'])
    } finally {
      setIssuing(false)
    }
  }

  async function handleCopy() {
    await navigator.clipboard.writeText(invitationUrl)
    setCopied(true)
  }

  if (notFound) {
    return (
      <>
        <Header />
        <main className="signup-page">
          <h1>ルームが見つかりません</h1>
          <Link to="/rooms" className={buttonVariants()}>
            ルーム一覧へ
          </Link>
        </main>
      </>
    )
  }

  return (
    <>
      <Header />
      <main className="signup-page">
        <h1>ルーム詳細</h1>
        {room && <p>相手の表示名: {room.partner_display_name}</p>}
        <p>テーマ機能は準備中です。</p>

        <Button onClick={handleIssueInvitation} disabled={issuing}>
          {issuing ? '発行中...' : '招待URLを発行する'}
        </Button>

        {errors.length > 0 && (
          <ul className="form-errors">
            {errors.map((error) => (
              <li key={error}>{error}</li>
            ))}
          </ul>
        )}

        {invitationUrl && (
          <div className="invitation-url">
            <p>{invitationUrl}</p>
            <Button onClick={handleCopy}>{copied ? 'コピーしました' : 'コピー'}</Button>
          </div>
        )}

        <Link to="/rooms" className={buttonVariants({ variant: 'outline' })}>
          ルーム一覧へ戻る
        </Link>
      </main>
    </>
  )
}

export default RoomDetailPage
