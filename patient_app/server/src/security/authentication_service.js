export class AuthenticationService {
  constructor() {
    this.requireAuth = process.env.REQUIRE_AUTH === 'true';
  }

  /**
   * Update auth requirement after env is loaded.
   * @param {{requireAuth?: boolean}} config
   */
  configure(config = {}) {
    if (typeof config.requireAuth === 'boolean') {
      this.requireAuth = config.requireAuth;
    }
  }

  /**
   * Validates the auth token.
   * In a production system, this would verify signature, expiry, and roles.
   * @param {string} token
   * @returns {boolean}
   */
  validateToken(token) {
    // Minimal check for presence/length; extend with JWT/HMAC verification as needed.
    return !!token && token.length > 10;
  }

  /**
   * Express middleware to enforce authentication.
   */
  middleware() {
    return (req, res, next) => {
      if (!this.requireAuth) {
        return next();
      }

      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
          error: {
            code: 'UNAUTHORIZED',
            message: 'Missing or invalid Authorization header',
            correlationId: req.correlationId,
            retryable: false,
          },
        });
      }

      const token = authHeader.split(' ')[1];
      if (!this.validateToken(token)) {
        return res.status(401).json({
          error: {
            code: 'UNAUTHORIZED',
            message: 'Invalid token',
            correlationId: req.correlationId,
            retryable: false,
          },
        });
      }

      // Token is valid (mock)
      next();
    };
  }
}

export const authenticationService = new AuthenticationService();
