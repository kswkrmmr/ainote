import { useEffect, useRef, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import Header from '@/components/Header'
import { Button, buttonVariants } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { getToken, clearToken } from '@/lib/auth'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

function ThemePage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [theme, setTheme] = useState(null)
  const [messages, setMessages] = useState(null)
  const [currentUserId, setCurrentUserId] = useState(null)
  const [notFound, setNotFound] = useState(false)
  const [originalBody, setOriginalBody] = useState('')
  const [translatedBody, setTranslatedBody] = useState(null)
  const [errors, setErrors] = useState([])
  const [translating, setTranslating] = useState(false)
  const [sending, setSending] = useState(false)
  const messageListBottomRef = useRef(null)

  useEffect(() => {
    messageListBottomRef.current?.scrollIntoView()
  }, [messages])

  useEffect(() => {
    const token = getToken()
    if (!token) {
      navigate('/login')
      return
    }

    fetch(`${apiBaseUrl}/api/me`, {
      headers: { Authorization: `Bearer ${token}` },
    })
      .then((response) => (response.ok ? response.json() : null))
      .then((data) => {
        if (data) {
          setCurrentUserId(data.id)
        }
      })

    fetch(`${apiBaseUrl}/api/themes/${id}`, {
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
          setTheme(data)
        }
      })

    fetch(`${apiBaseUrl}/api/themes/${id}/messages`, {
      headers: { Authorization: `Bearer ${token}` },
    })
      .then((response) => (response.ok ? response.json() : null))
      .then((data) => {
        if (data) {
          setMessages(data)
        }
      })
  }, [id, navigate])

  async function handlePreview(event) {
    event.preventDefault()
    setTranslating(true)
    setErrors([])

    try {
      const response = await fetch(`${apiBaseUrl}/api/themes/${id}/messages/preview`, {
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
        setErrors(data.errors || ['変換に失敗しました'])
        return
      }

      setTranslatedBody(data.translated_body)
    } catch {
      setErrors(['通信エラーが発生しました'])
    } finally {
      setTranslating(false)
    }
  }

  function handleBackToCompose() {
    setTranslatedBody(null)
    setErrors([])
  }

  async function handleSendMessage(event) {
    event.preventDefault()
    setSending(true)
    setErrors([])

    try {
      const response = await fetch(`${apiBaseUrl}/api/themes/${id}/messages`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify({
          message: { original_body: originalBody, translated_body: translatedBody },
        }),
      })
      const data = await response.json()

      if (!response.ok) {
        if (response.status === 401) {
          clearToken()
          navigate('/login')
          return
        }
        setErrors(data.errors || ['送信に失敗しました'])
        return
      }

      setMessages((prevMessages) => [...prevMessages, data])
      setOriginalBody('')
      setTranslatedBody(null)
    } catch {
      setErrors(['通信エラーが発生しました'])
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
          <ul className="message-list">
            {messages.map((message) => (
              <li
                key={message.id}
                className={
                  message.user_id === currentUserId
                    ? 'message-bubble message-bubble-self'
                    : 'message-bubble message-bubble-partner'
                }
              >
                {message.translated_body}
              </li>
            ))}
            <li ref={messageListBottomRef} />
          </ul>
        )}

        {translatedBody === null ? (
          <form onSubmit={handlePreview} className="signup-form message-form">
            <div className="form-field">
              <Label htmlFor="originalBody">メッセージを送る</Label>
              <Textarea
                id="originalBody"
                value={originalBody}
                onChange={(event) => setOriginalBody(event.target.value)}
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
            <Button type="submit" disabled={translating}>
              {translating ? '変換中...' : 'AIに変換してもらう'}
            </Button>
          </form>
        ) : (
          <form onSubmit={handleSendMessage} className="signup-form message-form">
            <div className="form-field">
              <Label htmlFor="translatedBody">AIによる変換結果（編集できます）</Label>
              <Textarea
                id="translatedBody"
                value={translatedBody}
                onChange={(event) => setTranslatedBody(event.target.value)}
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
            <div className="message-review-actions">
              <Button type="submit" disabled={sending}>
                {sending ? '送信中...' : '送信する'}
              </Button>
              <Button
                type="button"
                variant="outline"
                onClick={handleBackToCompose}
                disabled={sending}
              >
                変換前に戻す
              </Button>
            </div>
          </form>
        )}

        {theme && (
          <Link to={`/rooms/${theme.room_id}`} className={buttonVariants({ variant: 'outline' })}>
            一覧へ戻る
          </Link>
        )}
      </main>
    </>
  )
}

export default ThemePage
