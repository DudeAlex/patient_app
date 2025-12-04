# Design Document

## Overview

Stage 7e implements a comprehensive privacy and security layer for the AI Chat Companion system. The design focuses on protecting user data through rate limiting, data redaction, input validation, secure communication, and access control. All security measures are designed to be transparent to legitimate users while effectively preventing abuse and protecting sensitive information.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     AI Chat System                          │
│                                                             │
│  ┌──────────────┐                                          │
│  │   Flutter    │                                          │
│  │    Client    │                                          │
│  └──────┬───────┘                                          │
│         │                                                   │
│         │ HTTPS Only                                       │
│         │ (TLS 1.2+)                                       │
│         ▼                                                   │
│  ┌──────────────────────────────────────┐                 │
│  │    Security Middleware Layer         │                 │
│  │  ┌────────────────────────────────┐  │                 │
│  │  │  1. HTTPS Enforcement          │  │                 │
│  │  │  2. Authentication Check       │  │                 │
│  │  │  3. Rate Limiting              │  │                 │
│  │  │  4. Input Validation           │  │                 │
│  │  │  5. Request Sanitization       │  │                 │
│  │  └────────────────────────────────┘  │                 │
│  └──────────────┬───────────────────────┘                 │
│                 │                                           │
│                 ▼                                           │
│  ┌──────────────────────────────────────┐                 │
│  │      Backend API Endpoints           │                 │
│  │  - Chat endpoint                     │                 │
│  │  - Metrics endpoint (admin)          │                 │
│  │  - Config endpoint (admin)           │                 │
│  └──────────────┬───────────────────────┘                 │
│                 │                                           │
│                 ▼                                           │
│  ┌──────────────────────────────────────┐                 │
│  │      Logging & Monitoring            │                 │
│  │  ┌────────────────────────────────┐  │                 │
│  │  │  Data Redaction Filter         │  │                 │
│  │  │  - Redact PII before logging   │  │                 │
│  │  │  - Apply regex patterns        │  │                 │
│  │  │  - Replace with [REDACTED]     │  │                 │
│  │  └────────────────────────────────┘  │                 │
│  └──────────────┬───────────────────────┘                 │
│                 │                                           │
│                 ▼                                           │
│  ┌──────────────────────────────────────┐                 │
│  │      Security Monitoring             │                 │
│  │  - Rate limit violations             │                 │
│  │  - Auth failures                     │                 │
│  │  - Input validation failures         │                 │
│  │  - Suspicious activity alerts        │                 │
│  └──────────────────────────────────────┘                 │
└─────────────────────────────────────────────────────────────┘
```

### Request Flow with Security Layers

1. **Client Request** → HTTPS connection established
2. **HTTPS Enforcement** → Reject if not HTTPS
3. **Authentication** → Validate token
4. **Rate Limiting** → Check user quota
5. **Input Validation** → Validate message format
6. **Request Sanitization** → Remove malicious content
7. **Business Logic** → Process request
8. **Response** → Return to client
9. **Logging** → Redact PII, write to logs
10. **Monitoring** → Track security events

## Components and Interfaces

### 1. Rate Limiter

**Purpose**: Enforce request quotas per user

**Interface**:
```dart
abstract class RateLimiter {
  /// Check if user can make a request
  Future<RateLimitResult> checkLimit({
    required String userId,
    required RateLimitType type,
  });
  
  /// Record a request
  Future<void> recordRequest({
    required String userId,
  });
  
  /// Get remaining quota
  Future<RateLimitQuota> getQuota({
    required String userId,
  });
  
  /// Reset quotas (called at midnight UTC)
  Future<void> resetQuotas();
}

enum RateLimitType {
  perMinute,  // 10 requests
  perHour,    // 100 requests
  perDay,     // 500 requests
}

class RateLimitResult {
  final bool allowed;
  final int remaining;
  final DateTime resetTime;
  final String? message;
}

class RateLimitQuota {
  final int perMinuteRemaining;
  final int perHourRemaining;
  final int perDayRemaining;
  final DateTime nextReset;
}
```

**Implementation**: `RateLimiterImpl`
- In-memory storage with user ID → request timestamps
- Sliding window algorithm for accurate counting
- Automatic cleanup of old timestamps
- Thread-safe operations

### 2. Data Redaction Service

**Purpose**: Remove PII from logs and outputs

**Interface**:
```dart
abstract class DataRedactionService {
  /// Redact sensitive data from text
  String redact(String text);
  
  /// Add custom redaction pattern
  void addPattern({
    required String name,
    required RegExp pattern,
    String replacement = '[REDACTED]',
  });
  
  /// Check if text contains sensitive data
  bool containsSensitiveData(String text);
}
```

**Implementation**: `DataRedactionServiceImpl`
- Pre-configured patterns for common PII:
  - Names: `\b[A-Z][a-z]+ [A-Z][a-z]+\b`
  - Emails: `\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b`
  - Phones: `\b\d{3}[-.]?\d{3}[-.]?\d{4}\b`
  - SSNs: `\b\d{3}-\d{2}-\d{4}\b`
  - Addresses: Complex pattern for street addresses
- Configurable patterns via JSON file
- Fast regex matching with caching

### 3. Input Validator

**Purpose**: Validate and sanitize user input

**Interface**:
```dart
abstract class InputValidator {
  /// Validate chat message
  ValidationResult validateMessage(String message);
  
  /// Validate Space ID
  ValidationResult validateSpaceId(String spaceId);
  
  /// Sanitize input (remove malicious content)
  String sanitize(String input);
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final List<ValidationError> errors;
}

enum ValidationError {
  tooLong,
  tooShort,
  onlyWhitespace,
  invalidCharacters,
  potentialInjection,
  invalidFormat,
}
```

**Implementation**: `InputValidatorImpl`
- Length validation (1-10,000 characters)
- Whitespace-only detection
- SQL injection prevention
- XSS prevention
- Command injection prevention
- Space ID validation against known Spaces

### 4. HTTPS Enforcer

**Purpose**: Ensure all communication is encrypted

**Implementation** (Backend Middleware):
```javascript
function httpsEnforcer(req, res, next) {
  // Check if request is HTTPS
  if (!req.secure && req.get('x-forwarded-proto') !== 'https') {
    return res.status(403).json({
      error: 'HTTPS required',
      message: 'All requests must use HTTPS'
    });
  }
  next();
}
```

**Features**:
- Reject HTTP requests
- Support for reverse proxy (x-forwarded-proto)
- Configurable for development (allow HTTP in dev mode)

### 5. Authentication Service

**Purpose**: Verify user identity

**Interface**:
```dart
abstract class AuthenticationService {
  /// Validate authentication token
  Future<AuthResult> validateToken(String token);
  
  /// Generate new token
  Future<String> generateToken({
    required String userId,
    Duration expiry = const Duration(hours: 24),
  });
  
  /// Revoke token
  Future<void> revokeToken(String token);
}

class AuthResult {
  final bool isValid;
  final String? userId;
  final DateTime? expiry;
  final List<String> roles;
}
```

**Implementation**: `AuthenticationServiceImpl`
- JWT (JSON Web Token) based authentication
- Token expiry (24 hours default)
- Token revocation list
- Role-based access control (user, admin)

### 6. Security Monitor

**Purpose**: Track and alert on security events

**Interface**:
```dart
abstract class SecurityMonitor {
  /// Log security event
  Future<void> logEvent({
    required SecurityEventType type,
    required String userId,
    Map<String, dynamic>? metadata,
  });
  
  /// Get recent security events
  Future<List<SecurityEvent>> getRecentEvents({
    Duration window = const Duration(hours: 24),
  });
  
  /// Check for suspicious activity
  Future<bool> isSuspiciousActivity({
    required String userId,
  });
}

enum SecurityEventType {
  rateLimitViolation,
  authenticationFailure,
  inputValidationFailure,
  suspiciousActivity,
  adminAccessAttempt,
}

class SecurityEvent {
  final SecurityEventType type;
  final String userId;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
}
```

**Implementation**: `SecurityMonitorImpl`
- In-memory event storage (last 24 hours)
- Pattern detection for suspicious activity
- Integration with telemetry system (Stage 7b)
- Alert triggering for security incidents

## Data Models

### RateLimitConfig
```dart
class RateLimitConfig {
  final int perMinute;
  final int perHour;
  final int perDay;
  final double softLimitThreshold; // 0.8 = 80%
  final double warningThreshold;   // 0.9 = 90%
}
```

### RedactionPattern
```dart
class RedactionPattern {
  final String name;
  final RegExp pattern;
  final String replacement;
  final bool enabled;
}
```

### SecurityConfig
```dart
class SecurityConfig {
  final bool httpsOnly;
  final bool requireAuth;
  final Duration tokenExpiry;
  final RateLimitConfig rateLimits;
  final List<RedactionPattern> redactionPatterns;
  final int maxMessageLength;
}
```

## 
Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

Before defining correctness properties, let me analyze each acceptance criterion for testability:

### Acceptance Criteria Testing Prework:

**1.1-1.5** Rate limiting requirements
Thoughts: These are about counting requests over time windows. We can generate random requests and verify counts don't exceed limits.
Testable: yes - property

**2.1-2.5** Soft limits and warnings
Thoughts: These are about triggering warnings at specific thresholds. We can test the threshold logic.
Testable: yes - property

**3.1-3.5** Data redaction requirements
Thoughts: These are about pattern matching and replacement. We can generate text with PII and verify it's redacted.
Testable: yes - property

**4.1-4.5** Redaction patterns
Thoughts: These are about the redaction mechanism itself. We can test pattern application.
Testable: yes - property

**5.1-5.5** On-device data protection
Thoughts: These are about what should NOT be sent. We can verify absence of sensitive data in requests.
Testable: yes - property

**6.1-6.5** Input validation
Thoughts: These are about rejecting invalid input. We can generate invalid inputs and verify rejection.
Testable: yes - property

**7.1-7.5** Secure communication
Thoughts: These are about protocol enforcement. We can test HTTPS requirement.
Testable: yes - property

**8.1-8.5** Authentication
Thoughts: These are about token validation. We can test with valid/invalid tokens.
Testable: yes - property

**9.1-9.5** Admin access control
Thoughts: These are about authorization. We can test with different roles.
Testable: yes - property

**10.1-10.5** Security monitoring
Thoughts: These are about logging events. We can verify events are logged.
Testable: yes - property

### Property Reflection:

After reviewing all properties, I notice several can be combined:
- Rate limiting properties (1.1-1.5) can be combined into one property about quota enforcement
- Redaction properties (3.1-3.5, 4.1-4.5) can be combined into one property about PII removal
- Validation properties (6.1-6.5) can be combined into one property about input rejection

### Correctness Properties:

**Property 1: Rate limit enforcement**
*For any* user and time window, the number of allowed requests should never exceed the configured limit (10/min, 100/hr, 500/day).
**Validates: Requirements 1.1, 1.2, 1.3, 1.4**

**Property 2: Soft limit warnings**
*For any* user approaching their quota, warnings should be triggered at 80% and 90% thresholds.
**Validates: Requirements 2.1, 2.2**

**Property 3: PII redaction completeness**
*For any* text containing PII (names, emails, phones, SSNs, addresses), all instances should be replaced with [REDACTED].
**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**

**Property 4: Redaction pattern application**
*For any* text and redaction pattern, if the pattern matches, the text should be replaced with the configured replacement string.
**Validates: Requirements 4.1, 4.2, 4.3, 4.4**

**Property 5: On-device data protection**
*For any* request sent to the backend, it should not contain Information Item IDs or encryption keys.
**Validates: Requirements 5.1, 5.2**

**Property 6: Input validation rejection**
*For any* invalid input (too long, too short, only whitespace, malicious), the system should reject it with an appropriate error.
**Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5**

**Property 7: HTTPS enforcement**
*For any* request, if it's not HTTPS, it should be rejected with a 403 error.
**Validates: Requirements 7.1, 7.2**

**Property 8: Token validation**
*For any* authentication token, if it's expired or invalid, the request should be rejected.
**Validates: Requirements 8.1, 8.2, 8.3, 8.4**

**Property 9: Admin access control**
*For any* admin endpoint request, if the user doesn't have admin role, the request should be rejected.
**Validates: Requirements 9.1, 9.2, 9.3**

**Property 10: Security event logging**
*For any* security event (rate limit violation, auth failure, validation failure), it should be logged with timestamp and metadata.
**Validates: Requirements 10.1, 10.2, 10.3, 10.5**

## Error Handling

### Rate Limit Exceeded

**Response**:
```json
{
  "error": "rate_limit_exceeded",
  "message": "Too many requests. Please try again later.",
  "retryAfter": 60,
  "quota": {
    "perMinuteRemaining": 0,
    "perHourRemaining": 45,
    "perDayRemaining": 320
  }
}
```

**HTTP Status**: 429 (Too Many Requests)

### Authentication Failure

**Response**:
```json
{
  "error": "authentication_failed",
  "message": "Invalid or expired token"
}
```

**HTTP Status**: 401 (Unauthorized)

### Input Validation Failure

**Response**:
```json
{
  "error": "validation_failed",
  "message": "Invalid input",
  "errors": [
    {
      "field": "message",
      "error": "too_long",
      "maxLength": 10000
    }
  ]
}
```

**HTTP Status**: 400 (Bad Request)

### HTTPS Required

**Response**:
```json
{
  "error": "https_required",
  "message": "All requests must use HTTPS"
}
```

**HTTP Status**: 403 (Forbidden)

## Testing Strategy

### Unit Testing

**Focus**: Individual security components

**Test Cases**:
- RateLimiter: Quota tracking, window sliding, reset logic
- DataRedactionService: Pattern matching, replacement, custom patterns
- InputValidator: Length validation, whitespace detection, injection prevention
- AuthenticationService: Token generation, validation, expiry
- SecurityMonitor: Event logging, suspicious activity detection

**Tools**: Dart test framework, mockito for mocking

### Property-Based Testing

**Focus**: Universal security properties

**Properties to Test**:
1. Rate limit enforcement (Property 1)
2. Soft limit warnings (Property 2)
3. PII redaction completeness (Property 3)
4. Redaction pattern application (Property 4)
5. On-device data protection (Property 5)
6. Input validation rejection (Property 6)
7. HTTPS enforcement (Property 7)
8. Token validation (Property 8)
9. Admin access control (Property 9)
10. Security event logging (Property 10)

**Tools**: 
- Dart: `test` package with custom generators
- JavaScript (backend): `fast-check` library

**Configuration**:
- Minimum 100 iterations per property test
- Each test tagged with: `**Feature: llm-stage-7e-privacy-security, Property {number}: {property_text}**`

### Integration Testing

**Focus**: End-to-end security enforcement

**Test Scenarios**:
1. Send 11 requests in 1 minute, verify 11th is blocked
2. Send request with PII, verify it's redacted in logs
3. Send invalid input, verify rejection
4. Send HTTP request, verify rejection
5. Send request with expired token, verify rejection
6. Send admin request without admin role, verify rejection

### Security Testing

**Focus**: Penetration testing and vulnerability assessment

**Test Scenarios**:
1. SQL injection attempts
2. XSS attempts
3. Command injection attempts
4. Token tampering
5. Rate limit bypass attempts
6. HTTPS downgrade attacks

### Manual Testing

**Focus**: User experience and edge cases

**Test Scenarios**:
1. Approach rate limit, verify warnings appear
2. Exceed rate limit, verify error message is user-friendly
3. Test with various PII patterns
4. Test with edge case inputs (very long, special characters)

## Performance Considerations

### Rate Limiter Performance

**Target**: < 1ms per check

**Optimization**:
- In-memory storage (no database lookups)
- Efficient data structures (sorted lists for timestamps)
- Automatic cleanup of old timestamps
- Caching of quota calculations

### Redaction Performance

**Target**: < 5ms per message

**Optimization**:
- Pre-compiled regex patterns
- Pattern caching
- Early exit if no PII detected
- Parallel pattern matching for multiple patterns

### Input Validation Performance

**Target**: < 1ms per validation

**Optimization**:
- Fast length checks first
- Lazy evaluation (stop on first error)
- Cached validation results for repeated inputs

## Security Considerations

### Defense in Depth

Multiple layers of security:
1. HTTPS enforcement (transport layer)
2. Authentication (identity layer)
3. Rate limiting (abuse prevention)
4. Input validation (data layer)
5. Data redaction (privacy layer)
6. Security monitoring (detection layer)

### Fail Securely

**Principle**: When in doubt, deny access

**Examples**:
- If token validation fails, reject request
- If HTTPS cannot be verified, reject request
- If rate limit check fails, assume limit exceeded
- If redaction fails, don't log the data

### Least Privilege

**Principle**: Grant minimum necessary permissions

**Implementation**:
- Regular users: Chat access only
- Admin users: Chat + dashboard + config
- System: All access

### Audit Trail

**Principle**: Log all security-relevant events

**What to Log**:
- All authentication attempts (success and failure)
- All rate limit violations
- All input validation failures
- All admin access attempts
- All security alerts

## Deployment Considerations

### Configuration

**Environment Variables**:
```
HTTPS_ONLY=true
REQUIRE_AUTH=true
TOKEN_EXPIRY_HOURS=24
RATE_LIMIT_PER_MINUTE=10
RATE_LIMIT_PER_HOUR=100
RATE_LIMIT_PER_DAY=500
MAX_MESSAGE_LENGTH=10000
REDACTION_ENABLED=true
```

### Monitoring

**Metrics to Track**:
- Rate limit violations per hour
- Authentication failures per hour
- Input validation failures per hour
- Average request latency (with security checks)
- Security alerts triggered

### Rollout Strategy

1. Deploy security features (disabled by default)
2. Enable HTTPS enforcement
3. Enable authentication
4. Enable rate limiting (with high limits)
5. Gradually lower rate limits to target values
6. Enable data redaction
7. Enable input validation
8. Monitor for issues

## Future Enhancements

### Phase 2 (Optional)

- Two-factor authentication (2FA)
- IP-based rate limiting
- Geolocation-based access control
- Advanced threat detection (ML-based)
- Automated security scanning
- Compliance reporting (GDPR, HIPAA)

### Phase 3 (Optional)

- End-to-end encryption
- Zero-knowledge architecture
- Blockchain-based audit trail
- Federated authentication (OAuth, SAML)
- Advanced DDoS protection

---

## References

- **Requirements:** `.kiro/specs/llm-stage-7e-privacy-security/requirements.md`
- **LLM Stages Overview:** `docs/modules/ai/LLM_STAGES_OVERVIEW.md`
- **Stage 7b Design:** `.kiro/specs/llm-stage-7b-telemetry-analytics/design.md`
- **OWASP Top 10:** https://owasp.org/www-project-top-ten/
- **NIST Cybersecurity Framework:** https://www.nist.gov/cyberframework
