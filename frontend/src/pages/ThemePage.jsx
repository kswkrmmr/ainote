import { useEffect, useRef, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import Header from '@/components/Header'
import { Button, buttonVariants } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { createCableConsumer } from '@/lib/cable'
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
  const [summary, setSummary] = useState(null)
  const [summarizing, setSummarizing] = useState(false)
  const [summaryErrors, setSummaryErrors] = useState([])
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

  useEffect(() => {
    const token = getToken()
    if (!token) {
      return
    }

    const consumer = createCableConsumer(apiBaseUrl, token)
    const subscription = consumer.subscriptions.create(
      { channel: 'MessagesChannel', theme_id: id },
      { received: (data) => appendMessage(data) },
    )

    return () => {
      subscription.unsubscribe()
      consumer.disconnect()
    }
  }, [id])

  function appendMessage(newMessage) {
    setMessages((prevMessages) => {
      const currentMessages = prevMessages || []
      return currentMessages.some((message) => message.id === newMessage.id)
        ? currentMessages
        : [...currentMessages, newMessage]
    })
  }

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

  async function handleSummarize() {
    setSummarizing(true)
    setSummaryErrors([])

    try {
      const response = await fetch(`${apiBaseUrl}/api/themes/${id}/summary`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${getToken()}` },
      })
      const data = await response.json()

      if (!response.ok) {
        if (response.status === 401) {
          clearToken()
          navigate('/login')
          return
        }
        setSummaryErrors(data.errors || ['要約に失敗しました'])
        return
      }

      setSummary(data)
    } catch {
      setSummaryErrors(['通信エラーが発生しました'])
    } finally {
      setSummarizing(false)
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

      appendMessage(data)
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

        {messages && messages.length > 0 && (
          <div className="message-review-actions">
            <Button
              type="button"
              variant="outline"
              onClick={handleSummarize}
              disabled={summarizing}
            >
              {summarizing ? '整理中...' : '会話を整理する'}
            </Button>
          </div>
        )}

        {summaryErrors.length > 0 && (
          <ul className="form-errors">
            {summaryErrors.map((error) => (
              <li key={error}>{error}</li>
            ))}
          </ul>
        )}

        {summary && (
          <div className="summary-panel">
            {summary.participants.map((participant) => (
              <div key={participant.name}>
                <h3>{participant.name}さんの考え</h3>
                {participant.points.length > 0 ? (
                  <ul>
                    {participant.points.map((point) => (
                      <li key={point}>{point}</li>
                    ))}
                  </ul>
                ) : (
                  <p className="summary-panel-empty">特になし</p>
                )}
              </div>
            ))}
            <div>
              <h3>共通点</h3>
              {summary.common_points.length > 0 ? (
                <ul>
                  {summary.common_points.map((point) => (
                    <li key={point}>{point}</li>
                  ))}
                </ul>
              ) : (
                <p className="summary-panel-empty">特になし</p>
              )}
            </div>
            <div>
              <h3>未解決の論点</h3>
              {summary.open_issues.length > 0 ? (
                <ul>
                  {summary.open_issues.map((issue) => (
                    <li key={issue}>{issue}</li>
                  ))}
                </ul>
              ) : (
                <p className="summary-panel-empty">特になし</p>
              )}
            </div>
            <Button type="button" variant="outline" onClick={() => setSummary(null)}>
              閉じる
            </Button>
          </div>
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
