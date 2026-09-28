import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import Avatar from '@/components/Avatar'
import EmptyState from '@/components/EmptyState'
import Header from '@/components/Header'
import LineShareButton from '@/components/LineShareButton'
import { Button, buttonVariants } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { getToken } from '@/lib/auth'
import { useApi, readJson } from '@/lib/api'
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
  const [editingName, setEditingName] = useState(false)
  const [displayName, setDisplayName] = useState('')
  const [savingName, setSavingName] = useState(false)
  const [nameErrors, setNameErrors] = useState([])
  const [editingThemeId, setEditingThemeId] = useState(null)
  const [editingThemeTitle, setEditingThemeTitle] = useState('')
  const [savingTheme, setSavingTheme] = useState(false)
  const [themeUpdateErrors, setThemeUpdateErrors] = useState([])

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

  function startEditingName() {
    setDisplayName(room.partner_display_name)
    setNameErrors([])
    setEditingName(true)
  }

  async function handleSaveName(event) {
    event.preventDefault()
    setSavingName(true)
    setNameErrors([])

    try {
      const response = await api(`/api/rooms/${id}`, {
        method: 'PATCH',
        body: { room: { partner_display_name: displayName } },
      })
      if (!response) return

      const data = await readJson(response)

      if (!response.ok) {
        setNameErrors(data?.errors || [`変更に失敗しました（エラー ${response.status}）`])
        return
      }

      setRoom(data)
      setEditingName(false)
    } catch {
      setNameErrors(['通信エラーが発生しました'])
    } finally {
      setSavingName(false)
    }
  }

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

  function startEditingTheme(theme) {
    setEditingThemeId(theme.id)
    setEditingThemeTitle(theme.title)
    setThemeUpdateErrors([])
  }

  async function handleRenameTheme(event, themeId) {
    event.preventDefault()
    setSavingTheme(true)
    setThemeUpdateErrors([])

    try {
      const response = await api(`/api/themes/${themeId}`, {
        method: 'PATCH',
        body: { theme: { title: editingThemeTitle } },
      })
      if (!response) return

      const data = await readJson(response)

      if (!response.ok) {
        setThemeUpdateErrors(data?.errors || [`変更に失敗しました（エラー ${response.status}）`])
        return
      }

      setThemes((prevThemes) =>
        (prevThemes || []).map((theme) => (theme.id === themeId ? data : theme)),
      )
      setEditingThemeId(null)
    } catch {
      setThemeUpdateErrors(['通信エラーが発生しました'])
    } finally {
      setSavingTheme(false)
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

        {room && !editingName && (
          <Button variant="outline" onClick={startEditingName}>
            呼び名を変更する
          </Button>
        )}

        {room && editingName && (
          <form onSubmit={handleSaveName} className="signup-form">
            <div className="form-field">
              <Label htmlFor="partnerDisplayName">相手の呼び方</Label>
              <Input
                id="partnerDisplayName"
                type="text"
                value={displayName}
                onChange={(event) => setDisplayName(event.target.value)}
                required
              />
              <p className="form-hint">相手には表示されません</p>
            </div>
            {nameErrors.length > 0 && (
              <ul className="form-errors">
                {nameErrors.map((error) => (
                  <li key={error}>{error}</li>
                ))}
              </ul>
            )}
            <div className="message-review-actions">
              <Button type="submit" disabled={savingName}>
                {savingName ? '保存中...' : '保存する'}
              </Button>
              <Button type="button" variant="outline" onClick={() => setEditingName(false)}>
                キャンセル
              </Button>
            </div>
          </form>
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
                onClick={() => {
                  if (editingThemeId !== theme.id) {
                    navigate(`/themes/${theme.id}`)
                  }
                }}
              >
                {editingThemeId === theme.id ? (
                  <form
                    onSubmit={(event) => handleRenameTheme(event, theme.id)}
                    onClick={(event) => event.stopPropagation()}
                    className="theme-rename-form"
                  >
                    <Input
                      value={editingThemeTitle}
                      onChange={(event) => setEditingThemeTitle(event.target.value)}
                      aria-label="テーマ名"
                      required
                    />
                    {themeUpdateErrors.length > 0 && (
                      <ul className="form-errors">
                        {themeUpdateErrors.map((error) => (
                          <li key={error}>{error}</li>
                        ))}
                      </ul>
                    )}
                    <div className="message-review-actions">
                      <Button type="submit" disabled={savingTheme}>
                        {savingTheme ? '保存中...' : '保存する'}
                      </Button>
                      <Button
                        type="button"
                        variant="outline"
                        onClick={() => setEditingThemeId(null)}
                      >
                        キャンセル
                      </Button>
                    </div>
                  </form>
                ) : (
                  <>
                    <Link to={`/themes/${theme.id}`} className="theme-list-item-link">
                      {theme.title}
                    </Link>
                    <div className="theme-list-item-actions">
                      <Button
                        type="button"
                        variant="outline"
                        onClick={(event) => {
                          event.stopPropagation()
                          startEditingTheme(theme)
                        }}
                      >
                        名前を変更
                      </Button>
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
                    </div>
                  </>
                )}
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
                <div className="invitation-actions">
                  <LineShareButton message={invitationMessage} />
                  <Button variant="outline" onClick={handleCopy}>
                    {copied ? 'コピーしました' : 'コピー'}
                  </Button>
                </div>
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
