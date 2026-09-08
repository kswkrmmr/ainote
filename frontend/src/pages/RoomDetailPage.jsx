import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import Avatar from '@/components/Avatar'
import EmptyState from '@/components/EmptyState'
import Header from '@/components/Header'
import { Button, buttonVariants } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { getToken } from '@/lib/auth'
import { useApi } from '@/lib/api'
import { buildInvitationMessage } from '@/lib/invitation'
import { copyText } from '@/lib/clipboard'

function RoomDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const api = useApi()
  const [room, setRoom] = useState(null)
  const [notFound, setNotFound] = useState(false)
  const [invitationMessage, setInvitationMessage] = useState(null)
  const [issuing, setIssuing] = useState(false)
  const [copied, setCopied] = useState(false)
  const [copyFailed, setCopyFailed] = useState(false)
  const [errors, setErrors] = useState([])
  const [themes, setThemes] = useState(null)
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

    api(`/api/rooms/${id}`)
      .then((response) => {
        if (!response) return null

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

    api(`/api/rooms/${id}/themes`)
      .then((response) => (response?.ok ? response.json() : []))
      .then((data) => setThemes(data))
  }, [api, id, navigate])

  async function handleIssueInvitation() {
    setIssuing(true)
    setErrors([])
    setCopied(false)
    setCopyFailed(false)

    try {
      const response = await api(`/api/rooms/${id}/invitations`, { method: 'POST' })
      if (!response) return

      const data = await response.json()

      if (response.ok) {
        const url = `${window.location.origin}/invitations/${data.token}`
        setInvitationMessage(buildInvitationMessage(url))
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
    const succeeded = await copyText(invitationMessage)
    setCopied(succeeded)
    setCopyFailed(!succeeded)
  }

  async function handleCreateTheme(event) {
    event.preventDefault()
    setCreatingTheme(true)
    setThemeErrors([])

    try {
      const response = await api(`/api/rooms/${id}/themes`, {
        method: 'POST',
        body: { theme: { title: themeTitle } },
      })
      if (!response) return

      const data = await response.json()

      if (!response.ok) {
        setThemeErrors(data.errors || ['テーマの作成に失敗しました'])
        return
      }

      setThemes((prevThemes) => [...(prevThemes || []), data])
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
      const response = await api(`/api/themes/${themeId}`, { method: 'DELETE' })
      if (!response) return

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
        {room && (
          <div className="page-heading">
            <Avatar
              imageUrl={room.partner_avatar_url}
              name={room.partner_display_name}
              variant="partner"
            />
            <h1>{room.partner_display_name}とのルーム</h1>
          </div>
        )}

        {themes && themes.length === 0 && (
          <EmptyState>
            まだテーマがありません。
            <br />
            話したい話題ごとに「テーマ」を作成すると、そこでメッセージのやり取りができます。
          </EmptyState>
        )}

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

        {themes && themes.length > 0 && (
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
            <p className="form-hint">まだ相手が参加していません。招待URLを発行して送りましょう。</p>
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
                {copyFailed && (
                  <p className="form-hint">
                    コピーできませんでした。上のメッセージを選択してコピーしてください。
                  </p>
                )}
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
