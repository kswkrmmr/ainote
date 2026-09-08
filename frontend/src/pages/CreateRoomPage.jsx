import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import Header from '@/components/Header'
import { Button, buttonVariants } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { getToken } from '@/lib/auth'
import { useApi } from '@/lib/api'
import { buildInvitationMessage } from '@/lib/invitation'
import { copyText } from '@/lib/clipboard'

function CreateRoomPage() {
  const navigate = useNavigate()
  const api = useApi()
  const [partnerDisplayName, setPartnerDisplayName] = useState('')
  const [errors, setErrors] = useState([])
  const [submitting, setSubmitting] = useState(false)
  const [invitationMessage, setInvitationMessage] = useState(null)
  const [roomId, setRoomId] = useState(null)
  const [copied, setCopied] = useState(false)
  const [copyFailed, setCopyFailed] = useState(false)

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
      const roomResponse = await api('/api/rooms', {
        method: 'POST',
        body: { room: { partner_display_name: partnerDisplayName } },
      })
      if (!roomResponse) return

      const roomData = await roomResponse.json()

      if (!roomResponse.ok) {
        setErrors(roomData.errors || ['ルームの作成に失敗しました'])
        return
      }

      const invitationResponse = await api(`/api/rooms/${roomData.id}/invitations`, {
        method: 'POST',
      })
      if (!invitationResponse) return

      const invitationData = await invitationResponse.json()

      if (invitationResponse.ok) {
        const url = `${window.location.origin}/invitations/${invitationData.token}`
        setRoomId(roomData.id)
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
    const succeeded = await copyText(invitationMessage)
    setCopied(succeeded)
    setCopyFailed(!succeeded)
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
            {copyFailed && (
              <p className="form-hint">
                コピーできませんでした。上のメッセージを選択してコピーしてください。
              </p>
            )}
          </div>
          <p className="form-hint">続けて、このルームで話したいテーマを作りましょう。</p>
          <Link to={`/rooms/${roomId}`} className={buttonVariants()}>
            このルームを開く
          </Link>
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
