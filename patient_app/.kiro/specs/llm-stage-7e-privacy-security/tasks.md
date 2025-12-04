# Implementation Plan

## Overview

This implementation plan breaks down Stage 7e (Privacy & Security) into detailed, actionable tasks. The plan follows an incremental approach: implement rate limiting first, then data redaction, then input validation, then secure communication, then authentication, and finally monitoring.

**Task Breakdown:**
- **Main Tasks:** 10 task groups
- **Total Subtasks:** 80+ individual coding tasks (broken down for clarity)

**Important Notes:**
- Each task builds on previous tasks
- Tasks are broken down to minimize complexity
- Test as you go (unit tests after each component)
- Commit after each checkpoint
- Security features can be enabled incrementally

---

## Agent Instructions

**CRITICAL: After completing EACH task or checkpoint, you MUST:**

1. **Mark the task as complete** by checking the checkbox in this file
2. **Commit your changes** with the exact commit message specified in the checkpoint
3. **Stop and wait** for user confirmation before proceeding to the next task

---

## Task List

### Task 1: Set up security infrastructure

Create the foundational data models and configuration for security.

- [ ] 1.1 Create RateLimitConfig model
  - File: `lib/core/ai/chat/security/models/rate_limit_config.dart`
  - Fields: perMinute, perHour, perDay, softLimitThreshold, warningThreshold
  - _Requirements: 1.1-1.3, 2.1-2.2_

- [ ] 1.2 Create SecurityConfig model
  - File: `lib/core/ai/chat/security/models/security_config.dart`
  - Fields: httpsOnly, requireAuth, tokenExpiry, rateLimits, redactionPatterns, maxMessageLength
  - _Requirements: All_

- [ ] 1.3 Create RedactionPattern model
  - File: `lib/core/ai/chat/security/models/redaction_pattern.dart`
  - Fields: name, pattern (RegExp), replacement, enabled
  - _Requirements: 3.1-3.5, 4.1-4.5_

- [ ] 1.4 Create SecurityEvent model
  - File: `lib/core/ai/chat/security/models/security_event.dart`
  - Fields: type, userId, timestamp, metadata
  - Enum: SecurityEventType
  - _Requirements: 10.1-10.5_

- [ ] 1.5 Create RateLimitResult and RateLimitQuota models
  - File: `lib/core/ai/chat/security/models/rate_limit_result.dart`
  - _Requirements: 1.4, 2.3_

---

## Checkpoint 1: Commit data models

**Actions Required:**
1. Mark tasks 1.1-1.5 as complete [x]
2. Commit: `git commit -m "feat(stage7e): Add security data models"`
3. STOP and ask user before continuing

---

### Task 2: Implement rate limiter

Create the rate limiting service.

- [x] 2.1 Create RateLimiter interface
  - File: `lib/core/ai/chat/security/interfaces/rate_limiter.dart`
  - Methods: checkLimit(), recordRequest(), getQuota(), resetQuotas()
  - _Requirements: 1.1-1.5_

- [x] 2.2 Create RateLimiterImpl class skeleton
  - File: `lib/core/ai/chat/security/services/rate_limiter_impl.dart`
  - Create class implementing RateLimiter interface
  - Add in-memory storage (Map<String, List<DateTime>>)
  - _Requirements: 1.1-1.5_

- [x] 2.3 Implement checkLimit() method
  - Count requests in time window
  - Compare against limits (10/min, 100/hr, 500/day)
  - Return RateLimitResult
  - _Requirements: 1.1-1.3_

- [x] 2.4 Implement recordRequest() method
  - Add timestamp to user's request list
  - Store userId → List<DateTime>
  - _Requirements: 1.1-1.3_

- [x] 2.5 Implement getQuota() method
  - Calculate remaining quota for each time window
  - Return RateLimitQuota
  - _Requirements: 1.4, 2.3_

- [x] 2.6 Implement automatic cleanup
  - Remove timestamps older than 24 hours
  - Run cleanup periodically
  - _Requirements: 1.1-1.3_

- [x] 2.7 Implement soft limit warnings
  - Check if usage > 80% or > 90%
  - Add warning message to RateLimitResult
  - _Requirements: 2.1-2.2_

- [x] 2.8 Implement resetQuotas() method
  - Clear all stored timestamps
  - Called at midnight UTC
  - _Requirements: 2.4_

- [x] 2.9 Write RateLimiter tests

### Task 3: Implement data redaction service

- [x] 3.1 Create DataRedactionService interface
  - File: `lib/core/ai/chat/security/interfaces/data_redaction_service.dart`
  - Methods: redact(), addPattern(), containsSensitiveData()
  - _Requirements: 3.1-3.5, 4.1-4.5_

- [x] 3.2 Create DataRedactionServiceImpl class skeleton
  - File: `lib/core/ai/chat/security/services/data_redaction_service_impl.dart`
  - Create class implementing DataRedactionService interface
  - Add List<RedactionPattern> storage
  - _Requirements: 3.1-3.5_

- [x] 3.3 Add name redaction pattern
  - Pattern: `\b[A-Z][a-z]+ [A-Z][a-z]+\b`
  - Test with sample names
  - _Requirements: 3.1_

- [x] 3.4 Add email redaction pattern
  - Pattern: `\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b`
  - Test with sample emails
  - _Requirements: 3.2_

- [x] 3.5 Add phone redaction pattern
  - Pattern: `\b\d{3}[-.]?\d{3}[-.]?\d{4}\b`
  - Test with sample phone numbers
  - _Requirements: 3.3_

- [x] 3.6 Add SSN redaction pattern
  - Pattern: `\b\d{3}-\d{2}-\d{4}\b`
  - Test with sample SSNs
  - _Requirements: 3.4_

- [x] 3.7 Add address redaction pattern
  - Pattern for street addresses
  - Test with sample addresses
  - _Requirements: 3.5_

- [x] 3.8 Implement redact() method
  - Apply all patterns to input text
  - Replace matches with [REDACTED]
  - Return redacted text
  - _Requirements: 3.1-3.5, 4.2_

- [x] 3.9 Implement addPattern() method
  - Add custom pattern to list
  - Validate pattern is valid regex
  - _Requirements: 4.1, 4.3_

- [x] 3.10 Implement containsSensitiveData() method
  - Check if text matches any pattern
  - Return boolean
  - _Requirements: 4.4_

- [x] 3.11 Write DataRedactionService tests
  - File: `test/core/ai/chat/security/services/data_redaction_service_test.dart`
  - Test each PII type
  - Test custom patterns
  - Test edge cases
  - _Requirements: 3.1-3.5, 4.1-4.5_

### Task 4: Implement input validator

- [x] 4.1 Create InputValidator interface
  - File: `lib/core/ai/chat/security/interfaces/input_validator.dart`
  - Methods: validateMessage(), validateSpaceId(), sanitize()
  - _Requirements: 5.1-5.5_

- [x] 4.2 Implement InputValidatorImpl skeleton
  - File: `lib/core/ai/chat/security/services/input_validator_impl.dart`
  - _Requirements: 5.1-5.5_

- [x] 4.3 Add length validation (1-10,000 chars)
  - _Requirements: 5.1_

- [x] 4.4 Add whitespace-only check
  - _Requirements: 5.2_

- [x] 4.5 Add invalid character check
  - Reject control chars
  - _Requirements: 5.3_

- [x] 4.6 Add injection detection
  - Detect `<script>`, SQL keywords, `--`
  - _Requirements: 5.4_

- [x] 4.7 Implement sanitize()
  - Remove control chars, trim whitespace
  - _Requirements: 5.5_

- [x] 4.8 Validate Space IDs
  - Regex for `[A-Za-z0-9_-]+`, max length 64
  - _Requirements: 5.6_

- [x] 4.9 Write InputValidator tests
  - File: `test/core/ai/chat/security/services/input_validator_test.dart`
  - _Requirements: 5.1-5.6_
  - File: `test/core/ai/chat/security/services/rate_limiter_test.dart`
  - Test quota enforcement
  - Test soft limits
  - Test reset logic
  - _Requirements: 1.1-1.5, 2.1-2.5_

---

## Checkpoint 2: Commit rate limiter

**Actions Required:**
1. Mark tasks 2.1-2.9 as complete [x]
2. Commit: `git commit -m "feat(stage7e): Add rate limiting service"`
3. STOP and ask user before continuing

---

---

### Task 5: Implement HTTPS enforcement (Backend)

Add HTTPS enforcement middleware to backend.

- [x] 5.1 Create HTTPS enforcer middleware
  - File: `server/src/security/https_enforcer.js`
  - Check if request is HTTPS
  - Reject HTTP requests with 403
  - _Requirements: 7.1-7.2_

- [x] 5.2 Add development mode support
  - Allow HTTP in development
  - Environment variable: HTTPS_ONLY
  - _Requirements: 7.1_

- [x] 5.3 Add reverse proxy support
  - Check x-forwarded-proto header
  - Support for load balancers
  - _Requirements: 7.1_

- [x] 5.4 Write HTTPS enforcer tests
  - File: `server/test/security/https_enforcer.test.js`
  - Test HTTPS acceptance
  - Test HTTP rejection
  - Test development mode
  - _Requirements: 7.1-7.5_

### Task 6: Implement authentication service

- [x] 6.1 Create AuthenticationService interface
  - File: `lib/core/ai/chat/security/interfaces/authentication_service.dart`
  - Methods: validateToken(), generateToken(), revokeToken()
  - _Requirements: 8.1-8.5_

- [x] 6.2 Create AuthenticationServiceImpl class skeleton
  - File: `lib/core/ai/chat/security/services/authentication_service_impl.dart`
  - Create class implementing AuthenticationService interface
  - Add revocation list storage (Set<String>)
  - _Requirements: 8.1-8.5_

- [x] 6.3 Implement generateToken() method
  - Create JWT-like payload with userId, expiry, roles
  - Sign token with secret key
  - Return token string
  - _Requirements: 8.1, 8.2_

- [x] 6.4 Implement validateToken() method - basic validation
  - Parse token
  - Verify signature
  - Return AuthResult
  - _Requirements: 8.1, 8.4_

- [x] 6.5 Implement validateToken() method - expiry check
  - Check if token is expired
  - Compare expiry with current time
  - Return isValid = false if expired
  - _Requirements: 8.3_

- [x] 6.6 Implement validateToken() method - revocation check
  - Check if token is in revocation list
  - Return isValid = false if revoked
  - _Requirements: 8.5_

- [x] 6.7 Implement revokeToken() method
  - Add token to revocation list
  - Log revocation event
  - _Requirements: 8.5_

- [x] 6.8 Write AuthenticationService tests
  - File: `test/core/ai/chat/security/services/authentication_service_test.dart`
  - Test token generation
  - Test token validation
  - Test expiry
  - Test revocation
  - _Requirements: 8.1-8.5_

---

## Checkpoint 5: Commit HTTPS enforcement

**Actions Required:**
1. Mark tasks 5.1-5.4 as complete [x]
2. Commit: `git commit -m "feat(stage7e): Add HTTPS enforcement"`
3. STOP and ask user before continuing

---

### Task 6: Implement authentication service

Create token-based authentication.

- [ ] 6.1 Create AuthenticationService interface
  - File: `lib/core/ai/chat/security/interfaces/authentication_service.dart`
  - Methods: validateToken(), generateToken(), revokeToken()
  - _Requirements: 8.1-8.5_

- [ ] 6.2 Create AuthenticationServiceImpl class skeleton
  - File: `lib/core/ai/chat/security/services/authentication_service_impl.dart`
  - Create class implementing AuthenticationService interface
  - Add revocation list storage (Set<String>)
  - _Requirements: 8.1-8.5_

- [ ] 6.3 Implement generateToken() method
  - Create JWT payload with userId, expiry, roles
  - Sign token with secret key
  - Return token string
  - _Requirements: 8.1, 8.2_

- [ ] 6.4 Implement validateToken() method - basic validation
  - Parse JWT token
  - Verify signature
  - Return AuthResult
  - _Requirements: 8.1, 8.4_

- [ ] 6.5 Implement validateToken() method - expiry check
  - Check if token is expired
  - Compare expiry with current time
  - Return isValid = false if expired
  - _Requirements: 8.3_

- [ ] 6.6 Implement validateToken() method - revocation check
  - Check if token is in revocation list
  - Return isValid = false if revoked
  - _Requirements: 8.5_

- [ ] 6.7 Implement revokeToken() method
  - Add token to revocation list
  - Log revocation event
  - _Requirements: 8.5_

- [ ] 6.8 Write AuthenticationService tests
  - File: `test/core/ai/chat/security/services/authentication_service_test.dart`
  - Test token generation
  - Test token validation
  - Test expiry
  - Test revocation
  - _Requirements: 8.1-8.5_

---

## Checkpoint 6: Commit authentication

**Actions Required:**
1. Mark tasks 6.1-6.8 as complete [x]
2. Commit: `git commit -m "feat(stage7e): Add authentication service"`
3. STOP and ask user before continuing

---

### Task 7: Implement admin access control

Add role-based access control.

- [x] 7.1 Add roles to AuthResult
  - Extend AuthResult model
  - Add roles field (List<String>)
  - _Requirements: 9.1-9.5_

- [x] 7.2 Implement role checking
  - Check if user has required role
  - Reject if role missing
  - _Requirements: 9.1-9.3_

- [x] 7.3 Add admin middleware (Backend)
  - File: `server/src/security/admin_middleware.js`
  - Check for admin role
  - Reject non-admin requests
  - _Requirements: 9.1-9.3_

- [x] 7.4 Write admin access control tests
  - File: `server/test/security/admin_middleware.test.js`
  - Test admin access allowed
  - Test non-admin access denied
  - _Requirements: 9.1-9.5_

---

## Checkpoint 7: Commit access control

**Actions Required:**
1. Mark tasks 7.1-7.4 as complete [x]
2. Commit: `git commit -m "feat(stage7e): Add admin access control"`
3. STOP and ask user before continuing

---

### Task 8: Implement security monitor

Create security event tracking.

- [ ] 8.1 Create SecurityMonitor interface
  - File: `lib/core/ai/chat/security/interfaces/security_monitor.dart`
  - Methods: logEvent(), getRecentEvents(), isSuspiciousActivity()
  - _Requirements: 10.1-10.5_

- [ ] 8.2 Implement SecurityMonitorImpl
  - File: `lib/core/ai/chat/security/services/security_monitor_impl.dart`
  - In-memory event storage (24 hours)
  - Event logging
  - _Requirements: 10.1-10.5_

- [ ] 8.3 Implement suspicious activity detection
  - Pattern detection (multiple failures)
  - Alert triggering
  - _Requirements: 10.4_

- [ ] 8.4 Integrate with telemetry (Stage 7b)
  - Send security events to telemetry
  - Track security metrics
  - _Requirements: 10.5_

- [ ] 8.5 Write SecurityMonitor tests
  - File: `test/core/ai/chat/security/services/security_monitor_test.dart`
  - Test event logging
  - Test suspicious activity detection
  - _Requirements: 10.1-10.5_

---

## Checkpoint 8: Commit security monitor

**Actions Required:**
1. Mark tasks 8.1-8.5 as complete [x]
2. Commit: `git commit -m "feat(stage7e): Add security monitoring"`
3. STOP and ask user before continuing

---

### Task 9: Integrate security into AI chat flow

Wire up all security components.

- [ ] 9.1 Register security services in DI
  - File: `lib/core/di/bootstrap.dart`
  - Register RateLimiter
  - Register DataRedactionService
  - Register InputValidator
  - Register AuthenticationService
  - Register SecurityMonitor
  - _Requirements: All_

- [ ] 9.2 Add rate limiting to chat endpoint - check
  - In chat endpoint, call rateLimiter.checkLimit()
  - Get userId from request
  - _Requirements: 1.1-1.5_

- [ ] 9.3 Add rate limiting to chat endpoint - handle exceeded
  - If limit exceeded, return 429 error
  - Include retry-after header
  - Include remaining quota in response
  - _Requirements: 1.4, 1.5_

- [ ] 9.4 Add rate limiting to chat endpoint - record
  - If allowed, call rateLimiter.recordRequest()
  - Continue with request processing
  - _Requirements: 1.1-1.5_

- [ ] 9.5 Add input validation to chat endpoint - validate message
  - Call inputValidator.validateMessage()
  - Check ValidationResult
  - _Requirements: 6.1-6.2_

- [ ] 9.6 Add input validation to chat endpoint - handle invalid
  - If invalid, return 400 error
  - Include validation errors in response
  - _Requirements: 6.1-6.5_

- [ ] 9.7 Add input validation to chat endpoint - sanitize
  - If valid, call inputValidator.sanitize()
  - Use sanitized input for processing
  - _Requirements: 6.4, 6.5_

- [ ] 9.8 Add data redaction to logging - wrap logger
  - Create wrapper around AppLogger
  - Intercept all log calls
  - _Requirements: 3.1-3.5_

- [ ] 9.9 Add data redaction to logging - apply redaction
  - Call dataRedactionService.redact() on log messages
  - Pass redacted message to actual logger
  - _Requirements: 3.1-3.5_

- [ ] 9.10 Add authentication to chat endpoint
  - Extract token from request header
  - Call authenticationService.validateToken()
  - _Requirements: 8.1-8.4_

- [ ] 9.11 Add authentication error handling
  - If token invalid, return 401 error
  - Include error message
  - _Requirements: 8.1, 8.5_

- [ ] 9.12 Add authentication to admin endpoints
  - Apply same auth check to metrics endpoints
  - Apply same auth check to config endpoints
  - _Requirements: 9.1-9.3_

- [ ] 9.13 Add security event logging - rate limit violations
  - When rate limit exceeded, log event
  - Call securityMonitor.logEvent()
  - _Requirements: 10.1_

- [ ] 9.14 Add security event logging - auth failures
  - When auth fails, log event
  - Include userId and reason
  - _Requirements: 10.2_

- [ ] 9.15 Add security event logging - validation failures
  - When validation fails, log event
  - Include validation errors
  - _Requirements: 10.3_

- [ ] 9.16 Write integration test - rate limiting
  - File: `test/integration/security_integration_test.dart`
  - Send 11 requests, verify 11th blocked
  - _Requirements: 1.1-1.5_

- [ ] 9.17 Write integration test - input validation
  - Send invalid input, verify rejection
  - Send valid input, verify acceptance
  - _Requirements: 6.1-6.5_

- [ ] 9.18 Write integration test - authentication
  - Send request without token, verify 401
  - Send request with valid token, verify success
  - Send request with expired token, verify 401
  - _Requirements: 8.1-8.5_

- [ ] 9.19 Write integration test - data redaction
  - Send message with PII
  - Check logs, verify PII is redacted
  - _Requirements: 3.1-3.5_

- [ ] 9.20 Write integration test - end-to-end
  - Test all security features together
  - Verify they work in combination
  - _Requirements: All_

---

## Checkpoint 9: Commit security integration

**Actions Required:**
1. Mark tasks 9.1-9.20 as complete [x]
2. Commit: `git commit -m "feat(stage7e): Integrate security into AI chat flow"`
3. STOP and ask user before continuing

---

### Task 10: Property-based tests and documentation

Write property tests and create documentation.

- [ ] 10.1 Property 1: Rate limit enforcement
  - File: `test/core/ai/chat/security/properties/rate_limit_properties_test.dart`
  - **Feature: llm-stage-7e-privacy-security, Property 1: Rate limit enforcement**
  - **Validates: Requirements 1.1, 1.2, 1.3, 1.4**

- [ ] 10.2 Property 2: Soft limit warnings
  - **Feature: llm-stage-7e-privacy-security, Property 2: Soft limit warnings**
  - **Validates: Requirements 2.1, 2.2**

- [ ] 10.3 Property 3: PII redaction completeness
  - File: `test/core/ai/chat/security/properties/redaction_properties_test.dart`
  - **Feature: llm-stage-7e-privacy-security, Property 3: PII redaction completeness**
  - **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**

- [ ] 10.4 Property 4: Redaction pattern application
  - **Feature: llm-stage-7e-privacy-security, Property 4: Redaction pattern application**
  - **Validates: Requirements 4.1, 4.2, 4.3, 4.4**

- [ ] 10.5 Property 5: On-device data protection
  - File: `test/core/ai/chat/security/properties/data_protection_properties_test.dart`
  - **Feature: llm-stage-7e-privacy-security, Property 5: On-device data protection**
  - **Validates: Requirements 5.1, 5.2**

- [ ] 10.6 Property 6: Input validation rejection
  - File: `test/core/ai/chat/security/properties/validation_properties_test.dart`
  - **Feature: llm-stage-7e-privacy-security, Property 6: Input validation rejection**
  - **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5**

- [ ] 10.7 Property 7: HTTPS enforcement
  - File: `test/core/ai/chat/security/properties/https_properties_test.dart`
  - **Feature: llm-stage-7e-privacy-security, Property 7: HTTPS enforcement**
  - **Validates: Requirements 7.1, 7.2**

- [ ] 10.8 Property 8: Token validation
  - File: `test/core/ai/chat/security/properties/auth_properties_test.dart`
  - **Feature: llm-stage-7e-privacy-security, Property 8: Token validation**
  - **Validates: Requirements 8.1, 8.2, 8.3, 8.4**

- [ ] 10.9 Property 9: Admin access control
  - **Feature: llm-stage-7e-privacy-security, Property 9: Admin access control**
  - **Validates: Requirements 9.1, 9.2, 9.3**

- [ ] 10.10 Property 10: Security event logging
  - File: `test/core/ai/chat/security/properties/monitoring_properties_test.dart`
  - **Feature: llm-stage-7e-privacy-security, Property 10: Security event logging**
  - **Validates: Requirements 10.1, 10.2, 10.3, 10.5**

- [ ] 10.11 Create manual test scenarios document
  - File: `docs/modules/ai/STAGE_7E_MANUAL_TEST_SCENARIOS.md`
  - Document security testing scenarios
  - _Requirements: All_

- [ ] 10.12 Create Stage 7e documentation
  - File: `docs/modules/ai/STAGE_7E_PRIVACY_SECURITY.md`
  - Document architecture and configuration
  - _Requirements: All_

- [ ] 10.13 Update LLM Stages Overview
  - File: `docs/modules/ai/LLM_STAGES_OVERVIEW.md`
  - Mark Stage 7e as complete
  - _Requirements: All_

---

## Checkpoint 10: Final commit

**Actions Required:**
1. Mark tasks 10.1-10.13 as complete [x]
2. Commit: `git commit -m "feat(stage7e): Complete Stage 7e - Privacy & Security"`
3. STOP and ask user before continuing

---

## Stage 7e Completion Criteria

Stage 7e is complete when:

- [ ] All 10 task groups completed (1-10)
- [ ] All 80+ subtasks completed
- [ ] All unit tests passing
- [ ] All 10 property-based tests passing
- [ ] All integration tests passing
- [ ] Security testing completed
- [ ] Manual testing validates security features work correctly
- [ ] Documentation complete
- [ ] All changes committed to git

---

## Summary

**Total Tasks**: 80+ subtasks across 10 main task groups (broken down into small, manageable steps)
**Estimated Time**: 2-3 days
**Key Deliverables**:
- Rate limiting service
- Data redaction service
- Input validation service
- HTTPS enforcement
- Authentication service
- Admin access control
- Security monitoring
- 10 property-based tests
- Complete documentation

**Next Stage**: Stage 7c (User Feedback & Quality), 7d (Tool Hooks), or 7f (Offline Support)
