import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import Header from '@/components/Header'
import { buttonVariants } from '@/components/ui/button'
import { getToken, clearToken } from '@/lib/auth'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

function ThemePage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [messages, setMessages] = useState(null)
  const [notFound, setNotFound] = useState(false)

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
      </main>
    </>
  )
}

export default ThemePage
