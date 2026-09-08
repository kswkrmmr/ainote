import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import Avatar from '@/components/Avatar'
import { Button, buttonVariants } from '@/components/ui/button'
import { getToken, clearToken } from '@/lib/auth'
import { apiFetch } from '@/lib/api'
import { cn } from '@/lib/utils'
import logo from '@/assets/logo.png'

const headerOutlineButton = cn(
  buttonVariants({ variant: 'outline' }),
  'border-primary text-primary hover:bg-primary/10',
)

function Header() {
  const loggedIn = Boolean(getToken())
  const [nickname, setNickname] = useState('')
  const [avatarUrl, setAvatarUrl] = useState(null)

  useEffect(() => {
    if (!loggedIn) {
      return
    }

    // ヘッダーは全画面に出るため、401でもログイン画面へは飛ばさず表示を諦めるだけにする
    apiFetch('/api/me')
      .then((response) => (response.ok ? response.json() : null))
      .then((data) => {
        if (data) {
          setNickname(data.nickname)
          setAvatarUrl(data.avatar_url)
        }
      })
  }, [loggedIn])

  async function handleLogout() {
    try {
      await apiFetch('/api/logout', { method: 'DELETE' })
    } finally {
      clearToken()
      window.location.href = '/'
    }
  }

  return (
    <header className="app-header">
      <Link to="/" className="app-header-logo">
        <img src={logo} alt="あいのて" />
      </Link>
      <nav className="app-header-nav">
        {loggedIn ? (
          <>
            {nickname && (
              <Link to="/profile" className="app-header-account">
                <Avatar imageUrl={avatarUrl} name={nickname} variant="self" />
                {nickname}さん
              </Link>
            )}
            <Link to="/rooms" className={headerOutlineButton}>
              ルーム一覧
            </Link>
            <Link to="/vent" className={headerOutlineButton}>
              気持ちの置き場
            </Link>
            <Button onClick={handleLogout}>ログアウト</Button>
          </>
        ) : (
          <>
            <Link to="/signup" className={buttonVariants()}>
              新規登録
            </Link>
            <Link to="/login" className={headerOutlineButton}>
              ログイン
            </Link>
          </>
        )}
      </nav>
    </header>
  )
}

export default Header
