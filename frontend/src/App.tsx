import { useAuth } from './hooks/useAuth'
import { ApiDemo } from './components/ApiDemo'
import './App.css'

export default function App() {
  const { isLoading, isAuthenticated, email, signIn, signOut, getIdToken } = useAuth()

  if (isLoading) {
    return (
      <div className="app">
        <p className="loading">Loading…</p>
      </div>
    )
  }

  return (
    <div className="app">
      <header className="header">
        <div className="header-inner">
          <h1 className="brand">Platform App</h1>
          {isAuthenticated ? (
            <div className="user-bar">
              <span className="user-email">{email}</span>
              <button className="btn-outline" onClick={signOut}>
                Sign out
              </button>
            </div>
          ) : (
            <button className="btn-primary" onClick={() => void signIn()}>
              Sign in
            </button>
          )}
        </div>
      </header>

      <main className="main">
        {isAuthenticated ? (
          <>
            <p className="welcome">
              Signed in successfully. Use the buttons below to call the backend API.
            </p>
            <ApiDemo getIdToken={getIdToken} />
          </>
        ) : (
          <div className="hero">
            <h2>Welcome to the Platform Template</h2>
            <p>
              This is a reusable starter template for AWS-hosted web applications. Sign in to
              explore the backend API connectivity.
            </p>
            <button className="btn-primary btn-large" onClick={() => void signIn()}>
              Sign in with Cognito
            </button>
          </div>
        )}
      </main>
    </div>
  )
}
