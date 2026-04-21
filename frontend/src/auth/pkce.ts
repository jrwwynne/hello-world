/**
 * PKCE (Proof Key for Code Exchange) helpers.
 *
 * Used with Cognito Hosted UI to perform a secure OAuth 2.0 authorisation code
 * flow without exposing a client secret in the browser.
 *
 * See: https://www.rfc-editor.org/rfc/rfc7636
 */

function base64UrlEncode(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer)
  let binary = ''
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i])
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}

/** Generates a cryptographically random 32-byte code verifier. */
export function generateCodeVerifier(): string {
  const buffer = new Uint8Array(32)
  crypto.getRandomValues(buffer)
  return base64UrlEncode(buffer.buffer)
}

/** Derives the S256 code challenge from a verifier. */
export async function generateCodeChallenge(verifier: string): Promise<string> {
  const encoder = new TextEncoder()
  const data = encoder.encode(verifier)
  const digest = await crypto.subtle.digest('SHA-256', data)
  return base64UrlEncode(digest)
}

/** Generates a random opaque state value for CSRF protection. */
export function generateState(): string {
  const buffer = new Uint8Array(16)
  crypto.getRandomValues(buffer)
  return base64UrlEncode(buffer.buffer)
}
