export class DataRedactionService {
  constructor() {
    this.PATTERNS = {
      EMAIL: /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g,
      PHONE: /(\+\d{1,2}\s?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}/g,
      SSN: /\b\d{3}-\d{2}-\d{4}\b/g,
    };
    this.REPLACEMENT = '[REDACTED]';
    this.enabled = true;
  }

  /**
   * Enable or disable redaction at runtime.
   * @param {boolean} enabled
   */
  setEnabled(enabled) {
    this.enabled = Boolean(enabled);
  }

  /**
   * Redacts PII from the given text.
   * @param {string} text
   * @returns {string}
   */
  redact(text) {
    if (!this.enabled || !text || typeof text !== 'string') return text;

    let redacted = text;
    redacted = redacted.replace(this.PATTERNS.EMAIL, this.REPLACEMENT);
    redacted = redacted.replace(this.PATTERNS.PHONE, this.REPLACEMENT);
    redacted = redacted.replace(this.PATTERNS.SSN, this.REPLACEMENT);

    return redacted;
  }
}

export const dataRedactionService = new DataRedactionService();
