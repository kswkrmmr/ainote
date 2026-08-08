import { Link } from 'react-router-dom'
import { Button, buttonVariants } from '@/components/ui/button'
import { getToken, clearToken } from '@/lib/auth'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

function Header() {
  const loggedIn = Boolean(getToken())

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
        あいのて
      </Link>
      <nav className="app-header-nav">
        {loggedIn ? (
          <>
            <Link to="/" className={buttonVariants({ variant: 'outline' })}>
              ルーム一覧
            </Link>
            <Button onClick={handleLogout}>ログアウト</Button>
          </>
        ) : (
          <>
            <Link to="/signup" className={buttonVariants()}>
              新規登録
            </Link>
            <Link to="/login" className={buttonVariants({ variant: 'outline' })}>
              ログイン
            </Link>
          </>
        )}
      </nav>
    </header>
  )
}

export default Header
