import { useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import Avatar from '@/components/Avatar'
import EmptyState from '@/components/EmptyState'
import Header from '@/components/Header'
import LineShareButton from '@/components/LineShareButton'
import { Button, buttonVariants } from '@/components/ui/button'
import { getToken } from '@/lib/auth'
import { useApi } from '@/lib/api'
import { buildInvitationMessage } from '@/lib/invitation'
import { copyText } from '@/lib/clipboard'

function RoomListPage() {
  const navigate = useNavigate()
  const api = useApi()
  const [rooms, setRooms] = useState(null)
  const [issuingRoomId, setIssuingRoomId] = useState(null)
  const [invitationMessages, setInvitationMessages] = useState({})
  const [copiedRoomId, setCopiedRoomId] = useState(null)
  const [copyFailedRoomId, setCopyFailedRoomId] = useState(null)
  const [deletingRoomId, setDeletingRoomId] = useState(null)

  useEffect(() => {
    const token = getToken()
    if (!token) {
      navigate('/login')
      return
    }

    api('/api/rooms')
      .then((response) => (response ? response.json() : null))
      .then((data) => {
        if (data) {
          setRooms(data)
        }
      })
  }, [api, navigate])

  async function handleReissueInvitation(roomId) {
    setIssuingRoomId(roomId)
    setCopiedRoomId(null)
    setCopyFailedRoomId(null)

    try {
      const response = await api(`/api/rooms/${roomId}/invitations`, { method: 'POST' })
      if (!response) return

      const data = await response.json()

      if (response.ok) {
        const url = `${window.location.origin}/invitations/${data.token}`
        setInvitationMessages((prevMessages) => ({
          ...prevMessages,
          [roomId]: buildInvitationMessage(url),
        }))
      }
    } finally {
      setIssuingRoomId(null)
    }
  }

  async function handleCopy(roomId) {
    const succeeded = await copyText(invitationMessages[roomId])
    setCopiedRoomId(succeeded ? roomId : null)
    setCopyFailedRoomId(succeeded ? null : roomId)
  }

  async function handleDeleteRoom(roomId) {
    if (!window.confirm('このルームを削除しますか?テーマやメッセージも全て削除されます。')) {
      return
    }

    setDeletingRoomId(roomId)

    try {
      const response = await api(`/api/rooms/${roomId}`, { method: 'DELETE' })
      if (!response) return

      if (response.ok) {
        setRooms((prevRooms) => prevRooms.filter((room) => room.id !== roomId))
      }
    } finally {
      setDeletingRoomId(null)
    }
  }

  return (
    <>
      <Header />
      <main className="signup-page">
        <h1>ルーム一覧</h1>
        <Link to="/rooms/new" className={buttonVariants()}>
          ルーム作成
        </Link>

        {rooms && rooms.length === 0 && (
          <EmptyState>
            まだルームがありません。ルームは「誰と話すか」の単位です。
            <br />
            まずは相手とのルームを作り、その中で話したいテーマ(「何を話すか」)を作成すると、相手を招待できます。
          </EmptyState>
        )}

        {rooms && rooms.length > 0 && (
          <ul className="room-list">
            {rooms.map((room) => (
              <li
                key={room.id}
                className="room-list-item"
                onClick={() => navigate(`/rooms/${room.id}`)}
              >
                <div className="room-list-item-header">
                  <Link to={`/rooms/${room.id}`} className="room-list-item-link">
                    <Avatar
                      imageUrl={room.partner_avatar_url}
                      name={room.partner_display_name}
                      variant="partner"
                    />
                    {room.partner_display_name}
                  </Link>
                  <button
                    type="button"
                    className="list-item-delete"
                    aria-label="ルームを削除"
                    onClick={(event) => {
                      event.stopPropagation()
                      handleDeleteRoom(room.id)
                    }}
                    disabled={deletingRoomId === room.id}
                  >
                    ×
                  </button>
                </div>

                {room.awaiting_partner && (
                  <div
                    className="room-list-invitation"
                    onClick={(event) => event.stopPropagation()}
                  >
                    <span className="room-list-status">招待中</span>
                    <Button
                      variant="outline"
                      onClick={() => handleReissueInvitation(room.id)}
                      disabled={issuingRoomId === room.id}
                    >
                      {issuingRoomId === room.id ? '発行中...' : 'もう一度招待する'}
                    </Button>

                    {invitationMessages[room.id] && (
                      <div className="invitation-url">
                        <p className="invitation-message">{invitationMessages[room.id]}</p>
                        <div className="invitation-actions">
                          <LineShareButton message={invitationMessages[room.id]} />
                          <Button variant="outline" onClick={() => handleCopy(room.id)}>
                            {copiedRoomId === room.id ? 'コピーしました' : 'コピー'}
                          </Button>
                        </div>
                        {copyFailedRoomId === room.id && (
                          <p className="form-hint">
                            コピーできませんでした。上のメッセージを選択してコピーしてください。
                          </p>
                        )}
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
