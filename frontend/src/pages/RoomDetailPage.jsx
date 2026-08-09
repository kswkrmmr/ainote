import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import Header from '@/components/Header'
import { buttonVariants } from '@/components/ui/button'
import { getToken, clearToken } from '@/lib/auth'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

function RoomDetailPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [room, setRoom] = useState(null)
  const [notFound, setNotFound] = useState(false)

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
  }, [id, navigate])

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
        {room && <p>相手の表示名: {room.partner_display_name}</p>}
        <p>テーマ機能は準備中です。</p>
        <Link to="/rooms" className={buttonVariants({ variant: 'outline' })}>
          ルーム一覧へ戻る
        </Link>
      </main>
    </>
  )
}

export default RoomDetailPage
