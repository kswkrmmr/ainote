import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import Header from '@/components/Header'
import { Button, buttonVariants } from '@/components/ui/button'
import { getToken, clearToken } from '@/lib/auth'
import { buildInvitationMessage } from '@/lib/invitation'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

function RoomListPage() {
  const navigate = useNavigate()
  const [rooms, setRooms] = useState(null)
  const [issuingRoomId, setIssuingRoomId] = useState(null)
  const [invitationMessages, setInvitationMessages] = useState({})
  const [copiedRoomId, setCopiedRoomId] = useState(null)

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

  async function handleReissueInvitation(roomId) {
    setIssuingRoomId(roomId)
    setCopiedRoomId(null)

    try {
      const response = await fetch(`${apiBaseUrl}/api/rooms/${roomId}/invitations`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${getToken()}` },
      })
      const data = await response.json()

      if (response.ok) {
        const url = `${window.location.origin}/invitations/${data.token}`
        setInvitationMessages((prevMessages) => ({
          ...prevMessages,
          [roomId]: buildInvitationMessage(url),
        }))
      } else if (response.status === 401) {
        clearToken()
        navigate('/login')
      }
    } finally {
      setIssuingRoomId(null)
    }
  }

  async function handleCopy(roomId) {
    await navigator.clipboard.writeText(invitationMessages[roomId])
    setCopiedRoomId(roomId)
  }

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
              <li key={room.id} className="room-list-item">
                <Link to={`/rooms/${room.id}`} className="room-list-item-link">
                  {room.partner_display_name}
                </Link>

                {room.awaiting_partner && (
                  <div className="room-list-invitation">
                    <p>承認待ち</p>
                    <Button
                      onClick={() => handleReissueInvitation(room.id)}
                      disabled={issuingRoomId === room.id}
                    >
                      {issuingRoomId === room.id ? '発行中...' : 'もう一度招待する'}
                    </Button>

                    {invitationMessages[room.id] && (
                      <div className="invitation-url">
                        <p className="invitation-message">{invitationMessages[room.id]}</p>
                        <Button onClick={() => handleCopy(room.id)}>
                          {copiedRoomId === room.id ? 'コピーしました' : 'コピー'}
                        </Button>
                      </div>
                    )}
                  </div>
                )}
              </li>
            ))}
          </ul>
        )}
      </main>
    </>
  )
}

export default RoomListPage
