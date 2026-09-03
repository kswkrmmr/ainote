import { useState } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import Header from '@/components/Header'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { setToken } from '@/lib/auth'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000'

function SignUpPage() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const redirect = searchParams.get('redirect')
  const [nickname, setNickname] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [passwordConfirmation, setPasswordConfirmation] = useState('')
  const [errors, setErrors] = useState([])
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    setSubmitting(true)
    setErrors([])

    try {
      const response = await fetch(`${apiBaseUrl}/api/users`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          user: { nickname, email, password, password_confirmation: passwordConfirmation },
        }),
      })
      const data = await response.json()

      if (response.ok) {
        setToken(data.token)
        navigate(redirect?.startsWith('/invitations/') ? redirect : '/rooms')
      } else {
        setErrors(data.errors || ['登録に失敗しました'])
      }
    } catch {
      setErrors(['通信エラーが発生しました'])
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <>
      <Header />
      <main className="signup-page">
        <h1>新規登録</h1>
        <form onSubmit={handleSubmit} className="signup-form">
          <div className="form-field">
            <Label htmlFor="nickname">ニックネーム</Label>
            <Input
              id="nickname"
              type="text"
              value={nickname}
              onChange={(event) => setNickname(event.target.value)}
              required
            />
          </div>
          <div className="form-field">
            <Label htmlFor="email">メールアドレス</Label>
            <Input
              id="email"
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              required
            />
          </div>
          <div className="form-field">
            <Label htmlFor="password">パスワード</Label>
            <Input
              id="password"
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              required
            />
          </div>
          <div className="form-field">
            <Label htmlFor="passwordConfirmation">パスワード(確認)</Label>
            <Input
              id="passwordConfirmation"
              type="password"
              value={passwordConfirmation}
              onChange={(event) => setPasswordConfirmation(event.target.value)}
              required
            />
          </div>
          {errors.length > 0 && (
            <ul className="form-errors">
              {errors.map((error) => (
                <li key={error}>{error}</li>
              ))}
            </ul>
          )}
          <Button type="submit" disabled={submitting}>
            {submitting ? '登録中...' : '登録する'}
          </Button>
        </form>
      </main>
    </>
  )
}

export default SignUpPage
