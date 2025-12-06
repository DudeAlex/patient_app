export class InputValidator {
  constructor() {
    this.MAX_LENGTH = 10000;
    // Basic XSS/Injection patterns to block
    this.BLOCKLIST_PATTERNS = [
      /<script\b[^>]*>([\s\S]*?)<\/script>/gim,
      /javascript:/gim,
      /vbscript:/gim,
      /onload=/gim,
      /onerror=/gim,
      /onclick=/gim,
    ];
  }

  /**
   * Adjust the max length at runtime (after env is loaded).
   * @param {number} maxLength
   */
  setMaxLength(maxLength) {
    if (Number.isFinite(maxLength) && maxLength > 0) {
      this.MAX_LENGTH = maxLength;
    }
  }

  /**
   * Validates the message content.
   * @param {string} message
   * @returns {{isValid: boolean, error?: string}}
   */
  validateMessage(message) {
    if (!message || typeof message !== 'string') {
      return { isValid: false, error: 'Message must be a non-empty string' };
    }

    if (message.trim().length === 0) {
      return { isValid: false, error: 'Message cannot be empty or whitespace only' };
    }

    if (message.length > this.MAX_LENGTH) {
      return { isValid: false, error: `Message exceeds max length of ${this.MAX_LENGTH}` };
    }

    // Check for malicious patterns
    for (const pattern of this.BLOCKLIST_PATTERNS) {
      if (pattern.test(message)) {
        return { isValid: false, error: 'Message contains potentially malicious content' };
      }
    }

    return { isValid: true };
  }

  /**
   * Sanitizes the input string by removing control characters and trimming.
   * @param {string} input
   * @returns {string}
   */
  sanitize(input) {
    if (typeof input !== 'string') return '';
    // Remove control characters (except newlines/tabs) and trim
    return input.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '').trim();
  }
}

export const inputValidator = new InputValidator();
