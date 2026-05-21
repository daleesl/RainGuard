import { useState } from 'react'
import { signInWithEmailAndPassword } from 'firebase/auth'
import { ShieldCheck } from 'lucide-react'
import { auth } from '../firebase'

export function AdminLogin({ error: accessError, onSignOut, status }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [message, setMessage] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)

  async function handleSubmit(event) {
    event.preventDefault()
    setMessage('')
    setIsSubmitting(true)

    try {
      await signInWithEmailAndPassword(auth, email.trim(), password)
    } catch (loginError) {
      setMessage(loginError.message)
    } finally {
      setIsSubmitting(false)
    }
  }

  const isChecking = status === 'checking'
  const isAccessBlocked = status === 'not-admin' || status === 'error'

  return (
    <main className="admin-login-page">
      <section className="admin-login-card" aria-label="RainGuard admin login">
        <div className="admin-login-mark">
          <ShieldCheck aria-hidden="true" size={28} strokeWidth={2} />
        </div>
        <p className="admin-login-eyebrow">Admin Operations</p>
        <h1>RainGuard</h1>
        <p className="admin-login-copy">
          Sign in with the admin account assigned to your barangay safety desk.
        </p>

        {isChecking ? (
          <p className="auth-state-message">Checking admin session...</p>
        ) : null}

        {accessError ? (
          <p className="auth-error-message">{accessError}</p>
        ) : null}
        {message ? <p className="auth-error-message">{message}</p> : null}

        {isAccessBlocked ? (
          <button className="admin-login-secondary" onClick={onSignOut} type="button">
            Sign Out
          </button>
        ) : (
          <form className="admin-login-form" onSubmit={handleSubmit}>
            <label>
              Email
              <input
                autoComplete="email"
                onChange={(event) => setEmail(event.target.value)}
                placeholder="admin@email.com"
                required
                type="email"
                value={email}
              />
            </label>
            <label>
              Password
              <input
                autoComplete="current-password"
                onChange={(event) => setPassword(event.target.value)}
                placeholder="Enter password"
                required
                type="password"
                value={password}
              />
            </label>
            <button className="admin-login-submit" disabled={isSubmitting} type="submit">
              {isSubmitting ? 'Signing in...' : 'Sign In'}
            </button>
          </form>
        )}
      </section>
    </main>
  )
}
