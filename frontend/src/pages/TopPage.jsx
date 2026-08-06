import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import '../App.css'
import heroImage from '../assets/hero.png'
import { Button, buttonVariants } from '@/components/ui/button'
import { getToken, clearToken } from '@/lib/auth'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

function TopPage() {
  const [currentUser, setCurrentUser] = useState(null)
  const [checkingSession, setCheckingSession] = useState(true)

  useEffect(() => {
    const token = getToken()
    if (!token) {
      setCheckingSession(false)
      return
    }

    fetch(`${apiBaseUrl}/api/me`, {
      headers: { Authorization: `Bearer ${token}` },
    })
      .then((response) => (response.ok ? response.json() : null))
      .then((data) => {
        if (data) {
          setCurrentUser(data)
        } else {
          clearToken()
        }
      })
      .finally(() => setCheckingSession(false))
  }, [])

  async function handleLogout() {
    const token = getToken()
    try {
      await fetch(`${apiBaseUrl}/api/logout`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      })
    } finally {
      clearToken()
      setCurrentUser(null)
    }
  }

  return (
    <main className="top-page">
      <img src={heroImage} alt="あいのてのイメージ画像" className="hero-image" />
      <p className="catchphrase">言葉ですれ違ってしまう気持ちを、落ち着いて伝え合えるように。</p>
      <p className="description">
        あいのては、AIが対話を支援することで、感情的にならずに大切な人と話し合えるようになるサービスです。
      </p>

      {checkingSession ? null : currentUser ? (
        <div className="session-status">
          <p>ようこそ、{currentUser.email} さん</p>
          <Button onClick={handleLogout}>ログアウト</Button>
        </div>
      ) : (
        <div className="session-status">
          <Link to="/signup" className={buttonVariants()}>
            はじめる
          </Link>
          <Link to="/login" className={buttonVariants({ variant: 'outline' })}>
            ログイン
          </Link>
        </div>
      )}
    </main>
  )
}

export default TopPage
