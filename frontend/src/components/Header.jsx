import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { Button, buttonVariants } from '@/components/ui/button'
import { getToken, clearToken } from '@/lib/auth'
import { cn } from '@/lib/utils'
import logo from '@/assets/logo.png'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'
const headerOutlineButton = cn(
  buttonVariants({ variant: 'outline' }),
  'border-primary text-primary hover:bg-primary/10',
)

function Header() {
  const loggedIn = Boolean(getToken())
  const [nickname, setNickname] = useState('')

  useEffect(() => {
    if (!loggedIn) {
      return
    }

    fetch(`${apiBaseUrl}/api/me`, {
      headers: { Authorization: `Bearer ${getToken()}` },
    })
      .then((response) => (response.ok ? response.json() : null))
      .then((data) => {
        if (data) {
          setNickname(data.nickname)
        }
      })
  }, [loggedIn])

  async function handleLogout() {
    const token = getToken()
    try {
      await fetch(`${apiBaseUrl}/api/logout`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      })
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
              <span className="app-header-account">
                <span className="avatar avatar-self" aria-hidden="true">
                  {nickname.charAt(0)}
                </span>
                {nickname}さん
              </span>
            )}
            <Link to="/rooms" className={headerOutlineButton}>
              ルーム一覧
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
