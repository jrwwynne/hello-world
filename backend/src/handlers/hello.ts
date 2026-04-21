import { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from 'aws-lambda'

/**
 * GET /hello
 *
 * Returns a static JSON greeting.  Replace this handler with real business
 * logic when adapting the template for a production application.
 */
export async function handleHello(
  _event: APIGatewayProxyEventV2,
): Promise<APIGatewayProxyResultV2> {
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      message: 'Hello from the platform backend!',
      timestamp: new Date().toISOString(),
    }),
  }
}
