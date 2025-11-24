import crypto from 'crypto';
import { LlmError, classifyLlmError } from './errors.js';
import { resolveChatModel } from './models.js';

const DEFAULT_MODEL = resolveChatModel(process.env.TOGETHER_MODEL);
const DEFAULT_TIMEOUT_MS = Number.parseInt(
  process.env.LLM_TIMEOUT_MS ?? '60000',
  10,
);

/**
 * Lightweight Together AI client with timeout and error classification.
 */
export class TogetherClient {
  constructor({
    apiKey = process.env.TOGETHER_API_KEY,
    model = DEFAULT_MODEL,
    timeoutMs = DEFAULT_TIMEOUT_MS,
  } = {}) {
    if (!apiKey) {
      throw new LlmError(
        'TOGETHER_API_KEY is required to call the LLM provider',
        { code: 'MISSING_API_KEY', retryable: false },
      );
    }
    this.apiKey = apiKey;
    this.model = model;
    this.timeoutMs = timeoutMs;
  }

  /**
   * Sends a chat completion request.
   * @param {Object} params
   * @param {Array<{role: string, content: string}>} params.messages
   * @param {string} [params.correlationId]
   * @param {number} [params.maxTokens]
   * @param {number} [params.temperature]
   * @returns {Promise<{message: string, finishReason: string, usage: object}>}
   */
  async sendChat({
    messages,
    correlationId = crypto.randomUUID(),
    maxTokens = 512,
    temperature = 0.2,
  }) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);

    try {
      const response = await fetch(
        'https://api.together.xyz/v1/chat/completions',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${this.apiKey}`,
            'X-Correlation-ID': correlationId,
          },
          body: JSON.stringify({
            model: this.model,
            max_tokens: maxTokens,
            temperature,
            messages,
          }),
          signal: controller.signal,
        },
      );

      const raw = await response.text();
      let json;
      try {
        json = raw ? JSON.parse(raw) : {};
      } catch (e) {
        throw new LlmError('Invalid JSON from provider', {
          status: response.status,
          code: 'INVALID_JSON',
          retryable: false,
          cause: e,
        });
      }

      if (!response.ok) {
        const retryAfter = response.headers.get('retry-after');
        throw classifyLlmError(response.status, json?.error?.message || raw, {
          retryAfter: retryAfter ? Number.parseInt(retryAfter, 10) : undefined,
        });
      }

      const choice = json?.choices?.[0];
      const message = choice?.message?.content ?? '';
      return {
        message,
        finishReason: choice?.finish_reason ?? 'unknown',
        usage: json?.usage ?? {},
        provider: 'together',
        correlationId,
      };
    } catch (error) {
      if (error.name === 'AbortError') {
        throw new LlmError(
          `LLM request timed out after ${this.timeoutMs}ms`,
          { status: 408, code: 'TIMEOUT', retryable: true, cause: error },
        );
      }
      if (error instanceof LlmError) {
        throw error;
      }
      throw new LlmError('LLM request failed', {
        status: 500,
        code: 'LLM_REQUEST_FAILED',
        retryable: true,
        cause: error,
      });
    } finally {
      clearTimeout(timer);
    }
  }
}
