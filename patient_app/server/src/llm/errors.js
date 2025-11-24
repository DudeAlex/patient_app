export class LlmError extends Error {
  constructor(message, { status, code, retryable = false, cause } = {}) {
    super(message);
    this.name = 'LlmError';
    this.status = status;
    this.code = code;
    this.retryable = retryable;
    this.cause = cause;
  }
}

export const classifyLlmError = (status, message, { retryAfter } = {}) => {
  if (status === 401 || status === 403) {
    return new LlmError(message || 'Unauthorized', {
      status,
      code: 'UNAUTHORIZED',
      retryable: false,
    });
  }

  if (status === 429) {
    return new LlmError(message || 'Rate limited', {
      status,
      code: 'RATE_LIMIT',
      retryable: true,
      retryAfter,
    });
  }

  if (status >= 500 || status === 408) {
    return new LlmError(message || 'Provider unavailable', {
      status,
      code: 'SERVER_ERROR',
      retryable: true,
    });
  }

  if (status >= 400) {
    return new LlmError(message || 'Validation failed', {
      status,
      code: 'VALIDATION_ERROR',
      retryable: false,
    });
  }

  return new LlmError(message || 'Unexpected LLM error', {
    status,
    code: 'UNKNOWN',
    retryable: false,
  });
};
