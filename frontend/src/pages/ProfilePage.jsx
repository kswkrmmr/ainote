import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import Avatar from '@/components/Avatar'
import Header from '@/components/Header'
import { Button, buttonVariants } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { getToken, clearToken } from '@/lib/auth'
import { useApi, readJson } from '@/lib/api'
import { lineButtonClass, lineFriendUrl } from '@/lib/line'
import { cn } from '@/lib/utils'

function ProfilePage() {
  const navigate = useNavigate()
  const api = useApi()
  const [nickname, setNickname] = useState('')
  const [avatarUrl, setAvatarUrl] = useState(null)
  const [avatarFile, setAvatarFile] = useState(null)
  const [avatarPreviewUrl, setAvatarPreviewUrl] = useState(null)
  const [removeAvatar, setRemoveAvatar] = useState(false)
  const [email, setEmail] = useState('')
  const [initialEmail, setInitialEmail] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [newPasswordConfirmation, setNewPasswordConfirmation] = useState('')
  const [currentPassword, setCurrentPassword] = useState('')
  const [errors, setErrors] = useState([])
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const [lineLinked, setLineLinked] = useState(null)
  const [lineOnly, setLineOnly] = useState(false)
  const [unlinkingLine, setUnlinkingLine] = useState(false)
  const [lineErrors, setLineErrors] = useState([])
  const [withdrawing, setWithdrawing] = useState(false)
  const [withdrawErrors, setWithdrawErrors] = useState([])

  useEffect(() => {
    const token = getToken()
    if (!token) {
      navigate('/login')
      return
    }

    api('/api/me')
      .then((response) => (response ? response.json() : null))
      .then((data) => {
        if (data) {
          setNickname(data.nickname)
          setAvatarUrl(data.avatar_url)
          setEmail(data.email)
          setInitialEmail(data.email)
          setLineLinked(data.line_linked)
          setLineOnly(data.line_only)
        }
      })
  }, [api, navigate])

  function handleAvatarChange(event) {
    const file = event.target.files?.[0] || null
    setAvatarFile(file)
    setAvatarPreviewUrl(file ? URL.createObjectURL(file) : null)
    setRemoveAvatar(false)
  }

  async function handleWithdraw() {
    if (
      !window.confirm(
        '退会すると、このアカウントではログインできなくなります。\n' +
          'あなたが書いたメッセージは、相手の画面には残ります。\n' +
          '本当に退会しますか?',
      )
    ) {
      return
    }

    setWithdrawing(true)
    setWithdrawErrors([])

    try {
      const response = await api('/api/me', { method: 'DELETE' })
      if (!response) return

      if (!response.ok) {
        const data = await readJson(response)
        setWithdrawErrors(data?.errors || [`退会に失敗しました（エラー ${response.status}）`])
        return
      }

      clearToken()
      window.location.href = '/'
    } catch {
      setWithdrawErrors(['通信エラーが発生しました'])
    } finally {
      setWithdrawing(false)
    }
  }

  async function handleUnlinkLine() {
    if (!window.confirm('LINEとの連携を解除しますか?')) {
      return
    }

    setUnlinkingLine(true)
    setLineErrors([])

    try {
      const response = await api('/api/line/account_link', { method: 'DELETE' })
      if (!response) return

      if (!response.ok) {
        const data = await readJson(response)
        setLineErrors(data?.errors || [`解除に失敗しました（エラー ${response.status}）`])
        return
      }

      setLineLinked(false)
    } catch {
      setLineErrors(['通信エラーが発生しました'])
    } finally {
      setUnlinkingLine(false)
    }
  }

  function handleRemoveAvatar() {
    setAvatarFile(null)
    setAvatarPreviewUrl(null)
    setRemoveAvatar(true)
  }

  async function handleSubmit(event) {
    event.preventDefault()
    setErrors([])
    setSaved(false)

    const emailChanged = email !== initialEmail
    const passwordChanging = newPassword.length > 0

    if ((emailChanged || passwordChanging) && !currentPassword) {
      setErrors(['メールアドレス・パスワードを変更する場合は現在のパスワードを入力してください'])
      return
    }

    setSaving(true)

    const formData = new FormData()
    formData.append('nickname', nickname)
    if (avatarFile) {
      formData.append('avatar', avatarFile)
    } else if (removeAvatar) {
      formData.append('remove_avatar', 'true')
    }
    if (emailChanged) {
      formData.append('email', email)
    }
    if (passwordChanging) {
      formData.append('password', newPassword)
      formData.append('password_confirmation', newPasswordConfirmation)
    }
    if (emailChanged || passwordChanging) {
      formData.append('current_password', currentPassword)
    }

    try {
      const response = await api('/api/me', { method: 'PATCH', body: formData })
      if (!response) return

      const data = await readJson(response)

      if (!response.ok) {
        setErrors(data?.errors || [`更新に失敗しました（エラー ${response.status}）`])
        return
      }

      setNickname(data.nickname)
      setAvatarUrl(data.avatar_url)
      setAvatarFile(null)
      setAvatarPreviewUrl(null)
      setRemoveAvatar(false)
      setEmail(data.email)
      setInitialEmail(data.email)
      setNewPassword('')
      setNewPasswordConfirmation('')
      setCurrentPassword('')
      setSaved(true)
    } catch {
      setErrors(['通信エラーが発生しました'])
    } finally {
      setSaving(false)
    }
  }

  return (
    <>
      <Header />
      <main className="signup-page">
        <h1>プロフィール編集</h1>
        <form onSubmit={handleSubmit} className="signup-form">
          <div className="form-field profile-avatar-field">
            <Avatar
              imageUrl={avatarPreviewUrl || (removeAvatar ? null : avatarUrl)}
              name={nickname}
              variant="self"
            />
            <Label htmlFor="avatar" className={cn(buttonVariants({ variant: 'outline' }))}>
              画像を選ぶ
            </Label>
            <input
              id="avatar"
              type="file"
              accept="image/png,image/jpeg,image/webp"
              onChange={handleAvatarChange}
              hidden
            />
            {(avatarUrl || avatarFile) && !removeAvatar && (
              <Button type="button" variant="outline" onClick={handleRemoveAvatar}>
                画像を削除
              </Button>
            )}
            {removeAvatar && <p className="form-hint">保存すると画像が削除されます</p>}
          </div>
          <div className="form-field">
            <Label htmlFor="nickname">ニックネーム</Label>
            <Input
              id="nickname"
              type="text"
              value={nickname}
              onChange={(event) => setNickname(event.target.value)}
              required
            />
          </div>
          {!lineOnly && (
            <>
              <div className="form-field">
                <Label htmlFor="email">メールアドレス</Label>
                <Input
                  id="email"
                  type="email"
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                  required
                />
              </div>
              <div className="form-field">
                <Label htmlFor="newPassword">新しいパスワード</Label>
                <Input
                  id="newPassword"
                  type="password"
                  value={newPassword}
                  onChange={(event) => setNewPassword(event.target.value)}
                  autoComplete="new-password"
                />
                <p className="form-hint">変更しない場合は空欄のままにしてください</p>
              </div>
              {newPassword && (
                <div className="form-field">
                  <Label htmlFor="newPasswordConfirmation">新しいパスワード(確認)</Label>
                  <Input
                    id="newPasswordConfirmation"
                    type="password"
                    value={newPasswordConfirmation}
                    onChange={(event) => setNewPasswordConfirmation(event.target.value)}
                    autoComplete="new-password"
                  />
                </div>
              )}
              <div className="form-field">
                <Label htmlFor="currentPassword">現在のパスワード</Label>
                <Input
                  id="currentPassword"
                  type="password"
                  value={currentPassword}
                  onChange={(event) => setCurrentPassword(event.target.value)}
                  autoComplete="current-password"
                />
                <p className="form-hint">メールアドレス・パスワードを変更する場合のみ必要です</p>
              </div>
            </>
          )}
          {errors.length > 0 && (
            <ul className="form-errors">
              {errors.map((error) => (
                <li key={error}>{error}</li>
              ))}
            </ul>
          )}
          {saved && <p className="form-hint">更新しました</p>}
          <Button type="submit" disabled={saving}>
            {saving ? '保存中...' : '保存する'}
          </Button>
        </form>

        {lineLinked !== null && (
          <section className="line-link-section">
            <h2>LINE連携</h2>
            {lineLinked ? (
              <>
                <p>LINEと連携しています。</p>
                {lineOnly ? (
                  // LINEログインで作ったアカウントは、解除するとログインする手段が無くなる
                  <p className="form-hint">
                    このアカウントはLINEでログインしているため、連携の解除はできません。
                  </p>
                ) : (
                  <Button variant="outline" onClick={handleUnlinkLine} disabled={unlinkingLine}>
                    {unlinkingLine ? '解除中...' : 'LINE連携を解除する'}
                  </Button>
                )}
              </>
            ) : (
              <>
                <p className="form-hint">
                  公式アカウントを友だち追加すると、LINEに連携用のメッセージが届きます。
                </p>
                {lineFriendUrl && (
                  <a
                    href={lineFriendUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className={lineButtonClass}
                  >
                    LINEで友だち追加
                  </a>
                )}
              </>
            )}
            {lineErrors.length > 0 && (
              <ul className="form-errors">
                {lineErrors.map((error) => (
                  <li key={error}>{error}</li>
                ))}
              </ul>
            )}
          </section>
        )}

        <section className="withdraw-section">
          <h2>退会</h2>
          <p className="form-hint">
            退会すると、このアカウントではログインできなくなります。
            <br />
            あなたが書いたメッセージは、相手の画面には残ります。
          </p>
          {withdrawErrors.length > 0 && (
            <ul className="form-errors">
              {withdrawErrors.map((error) => (
                <li key={error}>{error}</li>
              ))}
            </ul>
          )}
          <Button variant="outline" onClick={handleWithdraw} disabled={withdrawing}>
            {withdrawing ? '退会処理中...' : '退会する'}
          </Button>
        </section>
      </main>
    </>
  )
}

export default ProfilePage
