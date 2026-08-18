import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import Header from '@/components/Header'
import { Button, buttonVariants } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { getToken, clearToken } from '@/lib/auth'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

function ThemePage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [messages, setMessages] = useState(null)
  const [notFound, setNotFound] = useState(false)
  const [originalBody, setOriginalBody] = useState('')
  const [sendErrors, setSendErrors] = useState([])
  const [sending, setSending] = useState(false)

  useEffect(() => {
    const token = getToken()
    if (!token) {
      navigate('/login')
      return
    }

    fetch(`${apiBaseUrl}/api/themes/${id}/messages`, {
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
          setMessages(data)
        }
      })
  }, [id, navigate])

  async function handleSendMessage(event) {
    event.preventDefault()
    setSending(true)
    setSendErrors([])

    try {
      const response = await fetch(`${apiBaseUrl}/api/themes/${id}/messages`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify({ message: { original_body: originalBody } }),
      })
      const data = await response.json()

      if (!response.ok) {
        if (response.status === 401) {
          clearToken()
          navigate('/login')
          return
        }
        setSendErrors(data.errors || ['送信に失敗しました'])
        return
      }

      setMessages((prevMessages) => [...prevMessages, data])
      setOriginalBody('')
    } catch {
      setSendErrors(['通信エラーが発生しました'])
    } finally {
      setSending(false)
    }
  }

  if (notFound) {
    return (
      <>
        <Header />
        <main className="signup-page">
          <h1>テーマが見つかりません</h1>
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
        <h1>メッセージ</h1>

        {messages && messages.length === 0 && <p>まだメッセージはありません。</p>}

        {messages && messages.length > 0 && (
          <ul>
            {messages.map((message) => (
              <li key={message.id}>{message.translated_body}</li>
            ))}
          </ul>
        )}

        <form onSubmit={handleSendMessage} className="signup-form">
          <div className="form-field">
            <Label htmlFor="originalBody">メッセージを送る</Label>
            <Input
              id="originalBody"
              type="text"
              value={originalBody}
              onChange={(event) => setOriginalBody(event.target.value)}
              required
            />
          </div>
          {sendErrors.length > 0 && (
            <ul className="form-errors">
              {sendErrors.map((sendError) => (
                <li key={sendError}>{sendError}</li>
              ))}
            </ul>
          )}
          <Button type="submit" disabled={sending}>
            {sending ? '送信中...' : '送信する'}
          </Button>
        </form>
      </main>
    </>
  )
}

export default ThemePage
