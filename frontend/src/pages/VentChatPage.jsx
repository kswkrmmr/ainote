import { useEffect, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import Avatar from '@/components/Avatar'
import Header from '@/components/Header'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { getToken, clearToken } from '@/lib/auth'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

function VentChatPage() {
  const navigate = useNavigate()
  const [currentUserNickname, setCurrentUserNickname] = useState('')
  const [currentUserAvatarUrl, setCurrentUserAvatarUrl] = useState(null)
  const [history, setHistory] = useState([])
  const [input, setInput] = useState('')
  const [sending, setSending] = useState(false)
  const [errors, setErrors] = useState([])
  const messageListBottomRef = useRef(null)

  useEffect(() => {
    messageListBottomRef.current?.scrollIntoView()
  }, [history])

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
          setCurrentUserNickname(data.nickname)
          setCurrentUserAvatarUrl(data.avatar_url)
        }
      })
  }, [navigate])

  async function handleSend(event) {
    event.preventDefault()
    if (!input.trim()) {
      return
    }

    const nextHistory = [...history, { role: 'user', content: input }]
    setHistory(nextHistory)
    setInput('')
    setSending(true)
    setErrors([])

    try {
      const response = await fetch(`${apiBaseUrl}/api/vent_chats`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify({ messages: nextHistory }),
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

      setHistory([...nextHistory, { role: 'assistant', content: data.reply }])
    } catch {
      setErrors(['通信エラーが発生しました'])
    } finally {
      setSending(false)
    }
  }

  return (
    <>
      <Header />
      <main className="signup-page">
        <h1>気持ちの置き場</h1>
        <p className="form-hint">
          ここでのやり取りは保存されません。
          <br />
          モヤモヤする気持ちを吐き出して落ち着いたら、
          <br />
          パートナーと話してみましょう。
        </p>

        {history.length > 0 && (
          <ul className="message-list">
            {history.map((message, index) => {
              const isSelf = message.role === 'user'
              return (
                <li
                  key={index}
                  className={
                    isSelf ? 'message-row message-row-self' : 'message-row message-row-partner'
                  }
                >
                  <Avatar
                    imageUrl={isSelf ? currentUserAvatarUrl : null}
                    name={isSelf ? currentUserNickname : 'AI'}
                    variant={isSelf ? 'self' : 'partner'}
                  />
                  <span
                    className={
                      isSelf
                        ? 'message-bubble message-bubble-self'
                        : 'message-bubble message-bubble-partner'
                    }
                  >
                    {message.content}
                  </span>
                </li>
              )
            })}
            <li ref={messageListBottomRef} />
          </ul>
        )}

        <form onSubmit={handleSend} className="signup-form message-form">
          <div className="form-field">
            <Label htmlFor="ventInput">今の気持ちを書いてみましょう</Label>
            <Textarea
              id="ventInput"
              value={input}
              onChange={(event) => setInput(event.target.value)}
            />
          </div>
          {errors.length > 0 && (
            <ul className="form-errors">
              {errors.map((error) => (
                <li key={error}>{error}</li>
              ))}
            </ul>
          )}
          <Button type="submit" disabled={sending || !input.trim()}>
            {sending ? '送信中...' : '送信する'}
          </Button>
        </form>
      </main>
    </>
  )
}

export default VentChatPage
