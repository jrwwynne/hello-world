import { useState } from 'react'

interface ApiDemoProps {
  getIdToken: () => string | null
}

interface ApiResult {
  status: 'idle' | 'loading' | 'success' | 'error'
  data: unknown
  error?: string
}

const API_URL = import.meta.env.VITE_API_URL

async function callApi(path: string, idToken: string | null): Promise<unknown> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  }
  if (idToken) {
    headers['Authorization'] = `Bearer ${idToken}`
  }

  const response = await fetch(`${API_URL}${path}`, { headers })

  if (!response.ok) {
    const text = await response.text()
    throw new Error(`HTTP ${response.status}: ${text}`)
  }

  return response.json()
}

function ResultPanel({ result }: { result: ApiResult }) {
  if (result.status === 'idle') return null

  if (result.status === 'loading') {
    return <p style={{ color: '#888' }}>Calling API…</p>
  }

  if (result.status === 'error') {
    return (
      <pre style={{ background: '#fee', border: '1px solid #faa', padding: '0.75rem', borderRadius: '4px', whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>
        {result.error}
      </pre>
    )
  }

  return (
    <pre style={{ background: '#f4f4f4', border: '1px solid #ddd', padding: '0.75rem', borderRadius: '4px', whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>
      {JSON.stringify(result.data, null, 2)}
    </pre>
  )
}

export function ApiDemo({ getIdToken }: ApiDemoProps) {
  const [helloResult, setHelloResult] = useState<ApiResult>({ status: 'idle', data: null })
  const [bedrockResult, setBedrockResult] = useState<ApiResult>({ status: 'idle', data: null })

  async function callHello() {
    setHelloResult({ status: 'loading', data: null })
    try {
      const data = await callApi('/hello', getIdToken())
      setHelloResult({ status: 'success', data })
    } catch (err) {
      setHelloResult({ status: 'error', data: null, error: String(err) })
    }
  }

  async function callBedrockHello() {
    setBedrockResult({ status: 'loading', data: null })
    try {
      const data = await callApi('/bedrock-hello', getIdToken())
      setBedrockResult({ status: 'success', data })
    } catch (err) {
      setBedrockResult({ status: 'error', data: null, error: String(err) })
    }
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
      <section>
        <h2 style={{ marginBottom: '0.5rem' }}>GET /hello</h2>
        <p style={{ color: '#555', marginBottom: '0.75rem', fontSize: '0.9rem' }}>
          A static response from the Lambda function.
        </p>
        <button onClick={() => void callHello()} disabled={helloResult.status === 'loading'}>
          Call /hello
        </button>
        <div style={{ marginTop: '0.75rem' }}>
          <ResultPanel result={helloResult} />
        </div>
      </section>

      <section>
        <h2 style={{ marginBottom: '0.5rem' }}>GET /bedrock-hello</h2>
        <p style={{ color: '#555', marginBottom: '0.75rem', fontSize: '0.9rem' }}>
          A connectivity test using Amazon Bedrock. Requires Bedrock model access to be enabled.
        </p>
        <button onClick={() => void callBedrockHello()} disabled={bedrockResult.status === 'loading'}>
          Call /bedrock-hello
        </button>
        <div style={{ marginTop: '0.75rem' }}>
          <ResultPanel result={bedrockResult} />
        </div>
      </section>
    </div>
  )
}
