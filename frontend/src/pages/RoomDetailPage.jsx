import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import Header from '@/components/Header'
import { Button, buttonVariants } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { getToken, clearToken } from '@/lib/auth'
import { buildInvitationMessage } from '@/lib/invitation'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

function RoomDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [room, setRoom] = useState(null)
  const [notFound, setNotFound] = useState(false)
  const [invitationMessage, setInvitationMessage] = useState(null)
  const [issuing, setIssuing] = useState(false)
  const [copied, setCopied] = useState(false)
  const [errors, setErrors] = useState([])
  const [themes, setThemes] = useState([])
  const [themeTitle, setThemeTitle] = useState('')
  const [themeErrors, setThemeErrors] = useState([])
  const [creatingTheme, setCreatingTheme] = useState(false)
  const [deletingThemeId, setDeletingThemeId] = useState(null)

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

    fetch(`${apiBaseUrl}/api/rooms/${id}/themes`, {
      headers: { Authorization: `Bearer ${token}` },
    })
      .then((response) => (response.ok ? response.json() : []))
      .then((data) => setThemes(data))
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
        const url = `${window.location.origin}/invitations/${data.token}`
        setInvitationMessage(buildInvitationMessage(url))
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
    await navigator.clipboard.writeText(invitationMessage)
    setCopied(true)
  }

  async function handleCreateTheme(event) {
    event.preventDefault()
    setCreatingTheme(true)
    setThemeErrors([])

    try {
      const response = await fetch(`${apiBaseUrl}/api/rooms/${id}/themes`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify({ theme: { title: themeTitle } }),
      })
      const data = await response.json()

      if (!response.ok) {
        if (response.status === 401) {
          clearToken()
          navigate('/login')
          return
        }
        setThemeErrors(data.errors || ['テーマの作成に失敗しました'])
        return
      }

      setThemes((prevThemes) => [...prevThemes, data])
      setThemeTitle('')
    } catch {
      setThemeErrors(['通信エラーが発生しました'])
    } finally {
      setCreatingTheme(false)
    }
  }

  async function handleDeleteTheme(themeId) {
    if (!window.confirm('このテーマを削除しますか?メッセージも全て削除されます。')) {
      return
    }

    setDeletingThemeId(themeId)

    try {
      const response = await fetch(`${apiBaseUrl}/api/themes/${themeId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${getToken()}` },
      })

      if (response.status === 401) {
        clearToken()
        navigate('/login')
        return
      }

      if (response.ok) {
        setThemes((prevThemes) => prevThemes.filter((theme) => theme.id !== themeId))
      }
    } finally {
      setDeletingThemeId(null)
    }
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
        {room && <p>{room.partner_display_name}さんとのチャットルーム</p>}

        <form onSubmit={handleCreateTheme} className="signup-form">
          <div className="form-field">
            <Label htmlFor="themeTitle">テーマを作成する</Label>
            <Input
              id="themeTitle"
              type="text"
              value={themeTitle}
              onChange={(event) => setThemeTitle(event.target.value)}
              required
            />
          </div>
          {themeErrors.length > 0 && (
            <ul className="form-errors">
              {themeErrors.map((themeError) => (
                <li key={themeError}>{themeError}</li>
              ))}
            </ul>
          )}
          <Button type="submit" disabled={creatingTheme}>
            {creatingTheme ? '作成中...' : 'テーマを作成する'}
          </Button>
        </form>

        {themes.length > 0 && (
          <ul className="theme-list">
            {themes.map((theme) => (
              <li
                key={theme.id}
                className="theme-list-item"
                onClick={() => navigate(`/themes/${theme.id}`)}
              >
                <Link to={`/themes/${theme.id}`} className="theme-list-item-link">
                  {theme.title}
                </Link>
                <button
                  type="button"
                  className="list-item-delete"
                  aria-label="テーマを削除"
                  onClick={(event) => {
                    event.stopPropagation()
                    handleDeleteTheme(theme.id)
                  }}
                  disabled={deletingThemeId === theme.id}
                >
                  ×
                </button>
              </li>
            ))}
          </ul>
        )}

        {room?.awaiting_partner && (
          <>
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

            {invitationMessage && (
              <div className="invitation-url">
                <p className="invitation-message">{invitationMessage}</p>
                <Button onClick={handleCopy}>{copied ? 'コピーしました' : 'コピー'}</Button>
              </div>
            )}
          </>
        )}

        <Link to="/rooms" className={buttonVariants({ variant: 'outline' })}>
          ルーム一覧へ戻る
        </Link>
      </main>
    </>
  )
}

export default RoomDetailPage
