/**
 * Lambda entry point.
 *
 * Routes incoming API Gateway HTTP API events to the appropriate handler
 * based on the routeKey (method + path).
 *
 * To add a new route:
 *   1. Create a handler in src/handlers/
 *   2. Add a case to the switch statement below
 *   3. Add the corresponding route in infra/modules/api_gateway/main.tf
 */

import { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from 'aws-lambda'
import { handleHello } from './handlers/hello'
import { handleBedrockHello } from './handlers/bedrockHello'

const corsHeaders = {
  'Access-Control-Allow-Origin': process.env.CORS_ALLOW_ORIGIN ?? '*',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  'Access-Control-Allow-Methods': 'GET,OPTIONS',
}

export const handler = async (
  event: APIGatewayProxyEventV2,
): Promise<APIGatewayProxyResultV2> => {
  // API Gateway HTTP API handles OPTIONS pre-flight when CORS is configured on
  // the API itself.  This is a belt-and-braces fallback.
  if (event.requestContext.http.method === 'OPTIONS') {
    return { statusCode: 204, headers: corsHeaders, body: '' }
  }

  try {
    let result: APIGatewayProxyResultV2

    switch (event.routeKey) {
      case 'GET /hello':
        result = await handleHello(event)
        break
      case 'GET /bedrock-hello':
        result = await handleBedrockHello(event)
        break
      default:
        result = {
          statusCode: 404,
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ error: 'Not found' }),
        }
    }

    // Inject CORS headers into every response.
    const typedResult = result as {
      statusCode: number
      headers?: Record<string, string>
      body: string
    }
    return {
      ...typedResult,
      headers: { ...corsHeaders, ...(typedResult.headers ?? {}) },
    }
  } catch (err) {
    console.error('Unhandled error:', err)
    return {
      statusCode: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      body: JSON.stringify({ error: 'Internal server error' }),
    }
  }
}
