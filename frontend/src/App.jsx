import { Routes, Route } from 'react-router-dom'
import TopPage from './pages/TopPage'
import SignUpPage from './pages/SignUpPage'
import LoginPage from './pages/LoginPage'
import CreateRoomPage from './pages/CreateRoomPage'
import RoomListPage from './pages/RoomListPage'
import RoomDetailPage from './pages/RoomDetailPage'
import InvitationPage from './pages/InvitationPage'
import ThemePage from './pages/ThemePage'
import ProfilePage from './pages/ProfilePage'
import VentChatPage from './pages/VentChatPage'
import LineLinkPage from './pages/LineLinkPage'
import LineCallbackPage from './pages/LineCallbackPage'

function App() {
  return (
    <Routes>
      <Route path="/" element={<TopPage />} />
      <Route path="/signup" element={<SignUpPage />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/rooms" element={<RoomListPage />} />
      <Route path="/rooms/new" element={<CreateRoomPage />} />
      <Route path="/rooms/:id" element={<RoomDetailPage />} />
      <Route path="/invitations/:token" element={<InvitationPage />} />
      <Route path="/themes/:id" element={<ThemePage />} />
      <Route path="/profile" element={<ProfilePage />} />
      <Route path="/vent" element={<VentChatPage />} />
      <Route path="/line/link" element={<LineLinkPage />} />
      <Route path="/line/callback" element={<LineCallbackPage />} />
    </Routes>
  )
}

export default App
