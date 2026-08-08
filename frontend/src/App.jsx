import { Routes, Route } from 'react-router-dom'
import TopPage from './pages/TopPage'
import SignUpPage from './pages/SignUpPage'
import LoginPage from './pages/LoginPage'
import CreateRoomPage from './pages/CreateRoomPage'

function App() {
  return (
    <Routes>
      <Route path="/" element={<TopPage />} />
      <Route path="/signup" element={<SignUpPage />} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/rooms/new" element={<CreateRoomPage />} />
    </Routes>
  )
}

export default App
