import { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from 'aws-lambda'
import { invokeClaudeModel } from '../lib/bedrockClient'

/**
 * GET /bedrock-hello
 *
 * Performs a minimal connectivity test against Amazon Bedrock.  Sends a short
 * prompt to a Claude model and returns the response.
 *
 * This handler demonstrates the Bedrock integration pattern.  In a real
 * application, replace the prompt and response handling with your own logic.
 *
 * IMPORTANT: Bedrock model access must be enabled in the AWS console before
 * this endpoint will succeed.  See docs/bedrock-setup.md.
 */
export async function handleBedrockHello(
  _event: APIGatewayProxyEventV2,
): Promise<APIGatewayProxyResultV2> {
  try {
    const result = await invokeClaudeModel(
      'Say hello in one sentence and confirm you are running on AWS Bedrock.',
    )

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: result.text,
        modelId: result.modelId,
        stopReason: result.stopReason,
        timestamp: new Date().toISOString(),
      }),
    }
  } catch (err) {
    const error = err as Error

    // Provide a clear error when Bedrock access has not been enabled, rather
    // than surfacing a raw SDK error to the caller.
    const isAccessDenied =
      error.name === 'AccessDeniedException' ||
      error.message?.includes('access') ||
      error.message?.includes('entitled')

    if (isAccessDenied) {
      console.warn('Bedrock access denied — model access may not be enabled:', error.message)
      return {
        statusCode: 403,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          error: 'Bedrock model access not enabled',
          detail:
            'Enable model access in the AWS Bedrock console for this account and region.  See docs/bedrock-setup.md.',
        }),
      }
    }

    console.error('Bedrock invocation error:', error)
    return {
      statusCode: 500,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        error: 'Bedrock invocation failed',
        detail: error.message,
      }),
    }
  }
}
