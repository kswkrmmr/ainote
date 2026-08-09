import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import Header from '@/components/Header'
import { buttonVariants } from '@/components/ui/button'
import { getToken, clearToken } from '@/lib/auth'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

function RoomListPage() {
  const navigate = useNavigate()
  const [rooms, setRooms] = useState(null)

  useEffect(() => {
    const token = getToken()
    if (!token) {
      navigate('/login')
      return
    }

    fetch(`${apiBaseUrl}/api/rooms`, {
      headers: { Authorization: `Bearer ${token}` },
    })
      .then((response) => {
        if (response.status === 401) {
          clearToken()
          navigate('/login')
          return null
        }
        return response.json()
      })
      .then((data) => {
        if (data) {
          setRooms(data)
        }
      })
  }, [navigate])

  return (
    <>
      <Header />
      <main className="signup-page">
        <h1>ルーム一覧</h1>
        <Link to="/rooms/new" className={buttonVariants()}>
          ルーム作成
        </Link>

        {rooms && rooms.length === 0 && <p>まだルームがありません。</p>}

        {rooms && rooms.length > 0 && (
          <ul className="room-list">
            {rooms.map((room) => (
              <li key={room.id}>
                <Link to={`/rooms/${room.id}`} className="room-list-item">
                  {room.partner_display_name}
                </Link>
              </li>
            ))}
          </ul>
        )}
      </main>
    </>
  )
}

export default RoomListPage
