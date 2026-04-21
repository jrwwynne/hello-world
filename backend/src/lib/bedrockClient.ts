/**
 * Minimal Bedrock client wrapper.
 *
 * Wraps `BedrockRuntimeClient` with a simple `invokeClaudeModel` helper that
 * handles the Anthropic Messages API format used by Claude models on Bedrock.
 *
 * The model ID is read from the BEDROCK_MODEL_ID environment variable, which
 * is set by the Lambda Terraform module.  Override it per-environment via
 * the `bedrock_model_id` Terraform variable.
 *
 * IMPORTANT: Some Bedrock models require explicit access enablement in the AWS
 * console before they can be invoked.  See docs/bedrock-setup.md.
 */

import {
  BedrockRuntimeClient,
  InvokeModelCommand,
  InvokeModelCommandOutput,
} from '@aws-sdk/client-bedrock-runtime'

const region = process.env.AWS_REGION ?? 'ap-southeast-2'
const modelId = process.env.BEDROCK_MODEL_ID ?? 'anthropic.claude-3-haiku-20240307-v1:0'

// Re-use the client across invocations (Lambda execution context warm-up).
const client = new BedrockRuntimeClient({ region })

interface BedrockTextResponse {
  text: string
  modelId: string
  stopReason: string
}

/**
 * Sends a single-turn text prompt to a Claude model via Bedrock and returns
 * the plain-text response.
 */
export async function invokeClaudeModel(prompt: string): Promise<BedrockTextResponse> {
  const requestBody = {
    anthropic_version: 'bedrock-2023-05-31',
    max_tokens: 256,
    messages: [{ role: 'user', content: prompt }],
  }

  const command = new InvokeModelCommand({
    modelId,
    contentType: 'application/json',
    accept: 'application/json',
    body: JSON.stringify(requestBody),
  })

  const output: InvokeModelCommandOutput = await client.send(command)
  const responseBody = JSON.parse(Buffer.from(output.body).toString('utf-8')) as {
    content: Array<{ type: string; text: string }>
    stop_reason: string
  }

  const text = responseBody.content.find((c) => c.type === 'text')?.text ?? ''
  return { text, modelId, stopReason: responseBody.stop_reason }
}
