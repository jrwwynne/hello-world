import { useEffect, useState, useCallback } from 'react'
import {
  cognitoConfig,
  TokenSet,
  loadTokens,
  saveTokens,
  clearTokens,
  saveVerifier,
  loadVerifier,
  buildAuthoriseUrl,
  buildLogoutUrl,
  exchangeCodeForTokens,
} from '../auth/cognitoConfig'
import { generateCodeVerifier, generateCodeChallenge, generateState } from '../auth/pkce'

interface AuthState {
  isLoading: boolean
  isAuthenticated: boolean
  email: string | null
  tokens: TokenSet | null
}

interface UseAuth extends AuthState {
  signIn: () => Promise<void>
  signOut: () => void
  getIdToken: () => string | null
}

/**
 * Decodes the payload of a JWT without verifying the signature.
 * Signature verification is handled server-side by API Gateway / Cognito.
 */
function decodeJwtPayload(token: string): Record<string, unknown> {
  try {
    const [, payload] = token.split('.')
    const padded = payload + '='.repeat((4 - (payload.length % 4)) % 4)
    return JSON.parse(atob(padded)) as Record<string, unknown>
  } catch {
    return {}
  }
}

export function useAuth(): UseAuth {
  const [state, setState] = useState<AuthState>({
    isLoading: true,
    isAuthenticated: false,
    email: null,
    tokens: null,
  })

  // On mount: check for an existing session or a redirect from Cognito.
  useEffect(() => {
    async function init() {
      const url = new URL(window.location.href)
      const code = url.searchParams.get('code')
      const returnedState = url.searchParams.get('state')

      // Handle redirect back from Cognito Hosted UI.
      if (code && returnedState) {
        const stored = loadVerifier()
        if (!stored || stored.state !== returnedState) {
          // State mismatch — possible CSRF.  Clear and restart.
          clearTokens()
          setState({ isLoading: false, isAuthenticated: false, email: null, tokens: null })
          return
        }

        try {
          const tokens = await exchangeCodeForTokens(code, stored.verifier, cognitoConfig)
          saveTokens(tokens)

          // Remove the code and state from the URL so refreshing doesn't re-exchange.
          url.searchParams.delete('code')
          url.searchParams.delete('state')
          window.history.replaceState({}, '', url.toString())

          const payload = decodeJwtPayload(tokens.idToken)
          setState({
            isLoading: false,
            isAuthenticated: true,
            email: (payload['email'] as string) ?? null,
            tokens,
          })
        } catch (err) {
          console.error('Token exchange failed:', err)
          clearTokens()
          setState({ isLoading: false, isAuthenticated: false, email: null, tokens: null })
        }
        return
      }

      // Check for an existing valid session.
      const existing = loadTokens()
      if (existing && existing.expiresAt > Date.now()) {
        const payload = decodeJwtPayload(existing.idToken)
        setState({
          isLoading: false,
          isAuthenticated: true,
          email: (payload['email'] as string) ?? null,
          tokens: existing,
        })
        return
      }

      setState({ isLoading: false, isAuthenticated: false, email: null, tokens: null })
    }

    init().catch(console.error)
  }, [])

  const signIn = useCallback(async () => {
    const verifier = generateCodeVerifier()
    const challenge = await generateCodeChallenge(verifier)
    const state = generateState()
    saveVerifier(verifier, state)
    window.location.href = buildAuthoriseUrl(cognitoConfig, challenge, state)
  }, [])

  const signOut = useCallback(() => {
    clearTokens()
    setState({ isLoading: false, isAuthenticated: false, email: null, tokens: null })
    window.location.href = buildLogoutUrl(cognitoConfig)
  }, [])

  const getIdToken = useCallback((): string | null => {
    const tokens = loadTokens()
    if (!tokens || tokens.expiresAt <= Date.now()) return null
    return tokens.idToken
  }, [])

  return { ...state, signIn, signOut, getIdToken }
}
