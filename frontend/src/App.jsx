import { Routes, Route } from 'react-router-dom'
import TopPage from './pages/TopPage'
import SignUpPage from './pages/SignUpPage'
import LoginPage from './pages/LoginPage'

function App() {
  return (
    <Routes>
      <Route path="/" element={<TopPage />} />
      <Route path="/signup" element={<SignUpPage />} />
      <Route path="/login" element={<LoginPage />} />
    </Routes>
  )
}

export default App
