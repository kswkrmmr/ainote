import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import Header from '@/components/Header'
import { Button, buttonVariants } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { getToken, clearToken } from '@/lib/auth'
import { buildInvitationMessage } from '@/lib/invitation'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

function CreateRoomPage() {
  const navigate = useNavigate()
  const [partnerDisplayName, setPartnerDisplayName] = useState('')
  const [errors, setErrors] = useState([])
  const [submitting, setSubmitting] = useState(false)
  const [invitationMessage, setInvitationMessage] = useState(null)
  const [copied, setCopied] = useState(false)

  useEffect(() => {
    if (!getToken()) {
      navigate('/login')
    }
  }, [navigate])

  async function handleSubmit(event) {
    event.preventDefault()
    setSubmitting(true)
    setErrors([])

    try {
      const roomResponse = await fetch(`${apiBaseUrl}/api/rooms`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify({ room: { partner_display_name: partnerDisplayName } }),
      })
      const roomData = await roomResponse.json()

      if (!roomResponse.ok) {
        if (roomResponse.status === 401) {
          clearToken()
          navigate('/login')
          return
        }
        setErrors(roomData.errors || ['ルームの作成に失敗しました'])
        return
      }

      const invitationResponse = await fetch(`${apiBaseUrl}/api/rooms/${roomData.id}/invitations`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${getToken()}` },
      })
      const invitationData = await invitationResponse.json()

      if (invitationResponse.ok) {
        const url = `${window.location.origin}/invitations/${invitationData.token}`
        setInvitationMessage(buildInvitationMessage(url))
      } else {
        setErrors(invitationData.errors || ['招待URLの発行に失敗しました'])
      }
    } catch {
      setErrors(['通信エラーが発生しました'])
    } finally {
      setSubmitting(false)
    }
  }

  async function handleCopy() {
    await navigator.clipboard.writeText(invitationMessage)
    setCopied(true)
  }

  if (invitationMessage) {
    return (
      <>
        <Header />
        <main className="signup-page">
          <h1>ルームを作成しました</h1>
          <div className="invitation-url">
            <p className="invitation-message">{invitationMessage}</p>
            <Button onClick={handleCopy}>{copied ? 'コピーしました' : 'コピー'}</Button>
          </div>
          <Link to="/rooms" className={buttonVariants({ variant: 'outline' })}>
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
        <h1>ルーム作成</h1>
        <form onSubmit={handleSubmit} className="signup-form">
          <div className="form-field">
            <Label htmlFor="partnerDisplayName">話したい相手(表示名)</Label>
            <Input
              id="partnerDisplayName"
              type="text"
              value={partnerDisplayName}
              onChange={(event) => setPartnerDisplayName(event.target.value)}
              required
            />
          </div>
          {errors.length > 0 && (
            <ul className="form-errors">
              {errors.map((error) => (
                <li key={error}>{error}</li>
              ))}
            </ul>
          )}
          <Button type="submit" disabled={submitting}>
            {submitting ? '作成中...' : '作成する'}
          </Button>
        </form>
      </main>
    </>
  )
}

export default CreateRoomPage