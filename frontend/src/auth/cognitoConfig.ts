/**
 * Cognito configuration derived from Vite environment variables.
 *
 * All VITE_* variables are injected at build time.  They are not secret —
 * Cognito app client IDs and pool IDs are public identifiers.  Do not add
 * anything secret here.
 *
 * Values come from Terraform outputs.  See docs/template-usage.md.
 */

export interface CognitoConfig {
  region: string
  userPoolId: string
  clientId: string
  hostedUiDomain: string
  redirectUri: string
}

export const cognitoConfig: CognitoConfig = {
  region: import.meta.env.VITE_COGNITO_REGION,
  userPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID,
  clientId: import.meta.env.VITE_COGNITO_CLIENT_ID,
  hostedUiDomain: import.meta.env.VITE_COGNITO_HOSTED_UI_DOMAIN,
  redirectUri: import.meta.env.VITE_COGNITO_REDIRECT_URI,
}

export interface TokenSet {
  accessToken: string
  idToken: string
  refreshToken?: string
  expiresAt: number // Unix ms
}

const STORAGE_KEY = 'auth_tokens'
const VERIFIER_KEY = 'pkce_verifier'
const STATE_KEY = 'pkce_state'

export function saveTokens(tokens: TokenSet): void {
  sessionStorage.setItem(STORAGE_KEY, JSON.stringify(tokens))
}

export function loadTokens(): TokenSet | null {
  const raw = sessionStorage.getItem(STORAGE_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw) as TokenSet
  } catch {
    return null
  }
}

export function clearTokens(): void {
  sessionStorage.removeItem(STORAGE_KEY)
  sessionStorage.removeItem(VERIFIER_KEY)
  sessionStorage.removeItem(STATE_KEY)
}

export function saveVerifier(verifier: string, state: string): void {
  sessionStorage.setItem(VERIFIER_KEY, verifier)
  sessionStorage.setItem(STATE_KEY, state)
}

export function loadVerifier(): { verifier: string; state: string } | null {
  const verifier = sessionStorage.getItem(VERIFIER_KEY)
  const state = sessionStorage.getItem(STATE_KEY)
  if (!verifier || !state) return null
  return { verifier, state }
}

export function buildAuthoriseUrl(
  config: CognitoConfig,
  codeChallenge: string,
  state: string,
): string {
  const params = new URLSearchParams({
    response_type: 'code',
    client_id: config.clientId,
    redirect_uri: config.redirectUri,
    scope: 'openid email profile',
    code_challenge_method: 'S256',
    code_challenge: codeChallenge,
    state,
  })
  return `https://${config.hostedUiDomain}/oauth2/authorize?${params.toString()}`
}

export function buildLogoutUrl(config: CognitoConfig): string {
  const params = new URLSearchParams({
    client_id: config.clientId,
    logout_uri: config.redirectUri,
  })
  return `https://${config.hostedUiDomain}/logout?${params.toString()}`
}

export async function exchangeCodeForTokens(
  code: string,
  verifier: string,
  config: CognitoConfig,
): Promise<TokenSet> {
  const url = `https://${config.hostedUiDomain}/oauth2/token`
  const body = new URLSearchParams({
    grant_type: 'authorization_code',
    client_id: config.clientId,
    code,
    redirect_uri: config.redirectUri,
    code_verifier: verifier,
  })

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: body.toString(),
  })

  if (!response.ok) {
    const text = await response.text()
    throw new Error(`Token exchange failed: ${text}`)
  }

  const data = await response.json()
  return {
    accessToken: data.access_token as string,
    idToken: data.id_token as string,
    refreshToken: data.refresh_token as string | undefined,
    expiresAt: Date.now() + (data.expires_in as number) * 1000,
  }
}
