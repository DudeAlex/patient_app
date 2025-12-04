# Implementation Plan

## Overview

This implementation plan breaks down Stage 7e (Privacy & Security) into detailed, actionable tasks. The plan follows an incremental approach: implement rate limiting first, then data redaction, then input validation, then secure communication, then authentication, and finally monitoring.

**Task Breakdown:**
- **Main Tasks:** 10 task groups
- **Total Subtasks:** 50+ individual coding tasks

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

- [ ] 2.1 Create RateLimiter interface
  - File: `lib/core/ai/chat/security/interfaces/rate_limiter.dart`
  - Methods: checkLimit(), recordRequest(), getQuota(), resetQuotas()
  - _Requirements: 1.1-1.5_

- [ ] 2.2 Implement RateLimiterImpl
  - File: `lib/core/ai/chat/security/services/rate_limiter_impl.dart`
  - In-memory storage with sliding window
  - Track requests per user per time window
  - _Requirements: 1.1-1.5_

- [ ] 2.3 Implement quota tracking
  - Track per-minute, per-hour, per-day quotas
  - Sliding window algorithm
  - Automatic cleanup of old timestamps
  - _Requirements: 1.1-1.3_

- [ ] 2.4 Implement soft limit warnings
  - Check 80% and 90% thresholds
  - Return warning messages
  - _Requirements: 2.1-2.2_

- [ ] 2.5 Write RateLimiter tests
  - File: `test/core/ai/chat/security/services/rate_limiter_test.dart`
  - Test quota enforcement
  - Test soft limits
  - Test reset logic
  - _Requirements: 1.1-1.5, 2.1-2.5_

---

## Checkpoint 2: Commit rate limiter

**Actions Required:**
1. Mark tasks 2.1-2.5 as complete [x]
2. Commit: `git commit -m "feat(stage7e): Add rate limiting service"`
3. STOP and ask user before continuing

---

### Task 3: Implement data redaction service

Create the PII redaction service.

- [ ] 3.1 Create DataRedactionService interface
  - File: `lib/core/ai/chat/security/interfaces/data_redaction_service.dart`
  - Methods: redact(), addPattern(), containsSensitiveData()
  - _Requirements: 3.1-3.5, 4.1-4.5_

- [ ] 3.2 Implement DataRedactionServiceImpl
  - File: `lib/core/ai/chat/security/services/data_redaction_service_impl.dart`
  - Pre-configured patterns for names, emails, phones, SSNs, addresses
  - Pattern matching and replacement
  - _Requirements: 3.1-3.5_

- [ ] 3.3 Add default redaction patterns
  - Names: `\b[A-Z][a-z]+ [A-Z][a-z]+\b`
  - Emails: `\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b`
  - Phones: `\b\d{3}[-.]?\d{3}[-.]?\d{4}\b`
  - SSNs: `\b\d{3}-\d{2}-\d{4}\b`
  - _Requirements: 3.1-3.5_

- [ ] 3.4 Implement custom pattern support
  - Load patterns from configuration
  - Add/remove patterns dynamically
  - _Requirements: 4.1-4.3_

- [ ] 3.5 Write DataRedactionService tests
  - File: `test/core/ai/chat/security/services/data_redaction_service_test.dart`
  - Test each PII type
  - Test custom patterns
  - Test edge cases
  - _Requirements: 3.1-3.5, 4.1-4.5_

---

## Checkpoint 3: Commit data redaction

**Actions Required:**
1. Mark tasks 3.1-3.5 as complete [x]
2. Commit: `git commit -m "feat(stage7e): Add data redaction service"`
3. STOP and ask user before continuing

---

### Task 4: Implement input validator

Create the input validation service.

- [ ] 4.1 Create InputValidator interface
  - File: `lib/core/ai/chat/security/interfaces/input_validator.dart`
  - Methods: validateMessage(), validateSpaceId(), sanitize()
  - _Requirements: 6.1-6.5_

- [ ] 4.2 Implement InputValidatorImpl
  - File: `lib/core/ai/chat/security/services/input_validator_impl.dart`
  - Length validation (1-10,000 characters)
  - Whitespace-only detection
  - _Requirements: 6.1-6.2_

- [ ] 4.3 Implement injection prevention
  - SQL injection detection
  - XSS detection
  - Command injection detection
  - _Requirements: 6.5_

- [ ] 4.4 Implement Space ID validation
  - Validate against known Spaces
  - Reject invalid IDs
  - _Requirements: 6.3_

- [ ] 4.5 Write InputValidator tests
  - File: `test/core/ai/chat/security/services/input_validator_test.dart`
  - Test length validation
  - Test injection prevention
  - Test Space ID validation
  - _Requirements: 6.1-6.5_

---

## Checkpoint 4: Commit input validator

**Actions Required:**
1. Mark tasks 4.1-4.5 as complete [x]
2. Commit: `git commit -m "feat(stage7e): Add input validation service"`
3. STOP and ask user before continuing

---

### Task 5: Implement HTTPS enforcement (Backend)

Add HTTPS enforcement middleware to backend.

- [ ] 5.1 Create HTTPS enforcer middleware
  - File: `server/src/security/https_enforcer.js`
  - Check if request is HTTPS
  - Reject HTTP requests with 403
  - _Requirements: 7.1-7.2_

- [ ] 5.2 Add development mode support
  - Allow HTTP in development
  - Environment variable: HTTPS_ONLY
  - _Requirements: 7.1_

- [ ] 5.3 Add reverse proxy support
  - Check x-forwarded-proto header
  - Support for load balancers
  - _Requirements: 7.1_

- [ ] 5.4 Write HTTPS enforcer tests
  - File: `server/test/security/https_enforcer.test.js`
  - Test HTTPS acceptance
  - Test HTTP rejection
  - Test development mode
  - _Requirements: 7.1-7.5_

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

- [ ] 6.2 Implement AuthenticationServiceImpl
  - File: `lib/core/ai/chat/security/services/authentication_service_impl.dart`
  - JWT-based authentication
  - Token generation and validation
  - _Requirements: 8.1-8.4_

- [ ] 6.3 Implement token expiry
  - 24-hour default expiry
  - Configurable expiry duration
  - _Requirements: 8.3_

- [ ] 6.4 Implement token revocation
  - Revocation list
  - Check on validation
  - _Requirements: 8.5_

- [ ] 6.5 Write AuthenticationService tests
  - File: `test/core/ai/chat/security/services/authentication_service_test.dart`
  - Test token generation
  - Test token validation
  - Test expiry
  - Test revocation
  - _Requirements: 8.1-8.5_

---

## Checkpoint 6: Commit authentication

**Actions Required:**
1. Mark tasks 6.1-6.5 as complete [x]
2. Commit: `git commit -m "feat(stage7e): Add authentication service"`
3. STOP and ask user before continuing

---

### Task 7: Implement admin access control

Add role-based access control.

- [ ] 7.1 Add roles to AuthResult
  - Extend AuthResult model
  - Add roles field (List<String>)
  - _Requirements: 9.1-9.5_

- [ ] 7.2 Implement role checking
  - Check if user has required role
  - Reject if role missing
  - _Requirements: 9.1-9.3_

- [ ] 7.3 Add admin middleware (Backend)
  - File: `server/src/security/admin_middleware.js`
  - Check for admin role
  - Reject non-admin requests
  - _Requirements: 9.1-9.3_

- [ ] 7.4 Write admin access control tests
  - File: `test/core/ai/chat/security/services/admin_access_test.dart`
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

- [ ] 9.1 Add rate limiting to chat endpoint
  - Check rate limit before processing
  - Return 429 if exceeded
  - _Requirements: 1.1-1.5_

- [ ] 9.2 Add input validation to chat endpoint
  - Validate message before processing
  - Return 400 if invalid
  - _Requirements: 6.1-6.5_

- [ ] 9.3 Add data redaction to logging
  - Redact PII before logging
  - Apply to all log statements
  - _Requirements: 3.1-3.5_

- [ ] 9.4 Add authentication to all endpoints
  - Validate token on every request
  - Return 401 if invalid
  - _Requirements: 8.1-8.5_

- [ ] 9.5 Add security event logging
  - Log all security events
  - Track violations
  - _Requirements: 10.1-10.5_

- [ ] 9.6 Update dependency injection
  - File: `lib/core/di/bootstrap.dart`
  - Register all security services
  - Wire up dependencies
  - _Requirements: All_

- [ ] 9.7 Write integration tests
  - File: `test/integration/security_integration_test.dart`
  - Test end-to-end security flow
  - Test all security features together
  - _Requirements: All_

---

## Checkpoint 9: Commit security integration

**Actions Required:**
1. Mark tasks 9.1-9.7 as complete [x]
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
- [ ] All 50+ subtasks completed
- [ ] All unit tests passing
- [ ] All 10 property-based tests passing
- [ ] All integration tests passing
- [ ] Security testing completed
- [ ] Manual testing validates security features work correctly
- [ ] Documentation complete
- [ ] All changes committed to git

---

## Summary

**Total Tasks**: 50+ subtasks across 10 main task groups
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
