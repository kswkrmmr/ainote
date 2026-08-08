import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import Header from '@/components/Header'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { getToken, clearToken } from '@/lib/auth'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

function CreateRoomPage() {
  const navigate = useNavigate()
  const [partnerDisplayName, setPartnerDisplayName] = useState('')
  const [errors, setErrors] = useState([])
  const [submitting, setSubmitting] = useState(false)
  const [created, setCreated] = useState(null)

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
      const response = await fetch(`${apiBaseUrl}/api/rooms`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify({ room: { partner_display_name: partnerDisplayName } }),
      })
      const data = await response.json()

      if (response.ok) {
        setCreated(data)
      } else if (response.status === 401) {
        clearToken()
        navigate('/login')
      } else {
        setErrors(data.errors || ['ルームの作成に失敗しました'])
      }
    } catch {
      setErrors(['通信エラーが発生しました'])
    } finally {
      setSubmitting(false)
    }
  }

  if (created) {
    return (
      <>
        <Header />
        <main className="signup-page">
          <h1>ルームを作成しました</h1>
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
