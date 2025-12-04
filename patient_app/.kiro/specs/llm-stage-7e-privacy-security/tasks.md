# Implementation Plan – Stage 7e (Privacy & Security)

## Overview
Incremental rollout of Stage 7e: rate limiting → redaction → input validation → HTTPS → auth → admin RBAC → monitoring → integration → property tests/docs.

## Agent Instructions
- After each checkpoint: mark tasks, commit with the specified message, and pause for confirmation.

## Task List

### Task 1: Set up security infrastructure — ✅ done
- [x] 1.1 RateLimitConfig model (`lib/core/ai/chat/security/models/rate_limit_config.dart`)
- [x] 1.2 SecurityConfig model
- [x] 1.3 RedactionPattern model
- [x] 1.4 SecurityEvent model (+ enum)
- [x] 1.5 RateLimitResult & RateLimitQuota models
**Checkpoint 1 commit:** `feat(stage7e): Add security data models`

### Task 2: Rate limiter — ✅ done
- [x] 2.1 RateLimiter interface
- [x] 2.2 RateLimiterImpl skeleton
- [x] 2.3 checkLimit()
- [x] 2.4 recordRequest()
- [x] 2.5 getQuota()
- [x] 2.6 Cleanup old timestamps
- [x] 2.7 Soft limit warnings
- [x] 2.8 resetQuotas()
- [x] 2.9 Tests (`test/core/ai/chat/security/services/rate_limiter_test.dart`)
**Checkpoint 2 commit:** `feat(stage7e): Add rate limiting service`

### Task 3: Data redaction — ✅ done
- [x] 3.1 DataRedactionService interface
- [x] 3.2 DataRedactionServiceImpl
- [x] 3.3 Name pattern
- [x] 3.4 Email pattern
- [x] 3.5 Phone pattern
- [x] 3.6 SSN pattern
- [x] 3.7 Address pattern
- [x] 3.8 redact()
- [x] 3.9 addPattern()
- [x] 3.10 containsSensitiveData()
- [x] 3.11 Tests (`test/core/ai/chat/security/services/data_redaction_service_test.dart`)
**Checkpoint 3 commit:** `feat(stage7e): Add data redaction service`

### Task 4: Input validator — ✅ done
- [x] 4.1 InputValidator interface
- [x] 4.2 InputValidatorImpl skeleton
- [x] 4.3 Length validation
- [x] 4.4 Whitespace check
- [x] 4.5 Invalid character check
- [x] 4.6 Injection detection
- [x] 4.7 sanitize()
- [x] 4.8 Space ID validation
- [x] 4.9 Tests (`test/core/ai/chat/security/services/input_validator_test.dart`)
**Checkpoint 4 commit:** `feat(stage7e): Add input validator`

### Task 5: HTTPS enforcement — ✅ done
- [x] 5.1 HTTPS enforcer middleware (`server/src/security/https_enforcer.js`)
- [x] 5.2 Dev mode support (HTTPS_ONLY env)
- [x] 5.3 Reverse proxy support (x-forwarded-proto)
- [x] 5.4 Tests (`server/test/security/https_enforcer.test.js`)
**Checkpoint 5 commit:** `feat(stage7e): Add HTTPS enforcement`

### Task 6: Authentication service — ✅ done
- [x] 6.1 AuthenticationService interface
- [x] 6.2 AuthenticationServiceImpl skeleton
- [x] 6.3 generateToken()
- [x] 6.4 validateToken() basic/signature
- [x] 6.5 validateToken() expiry
- [x] 6.6 validateToken() revocation
- [x] 6.7 revokeToken()
- [x] 6.8 Tests (`test/core/ai/chat/security/services/authentication_service_test.dart`)
**Checkpoint 6 commit:** `feat(stage7e): Add authentication service`

### Task 7: Admin access control — ✅ done
- [x] 7.1 Add roles to AuthResult
- [x] 7.2 Role checking
- [x] 7.3 Admin middleware (`server/src/security/admin_middleware.js`)
- [x] 7.4 Tests (`server/test/security/admin_middleware.test.js`)
**Checkpoint 7 commits:** `feat(stage7e): Add admin access control`, `feat(stage7e): Add admin middleware`

### Task 8: Security monitor — ☐ pending
- [ ] 8.1 SecurityMonitor interface
- [ ] 8.2 SecurityMonitorImpl (in-memory, 24h)
- [ ] 8.3 Suspicious activity detection
- [ ] 8.4 Telemetry integration
- [ ] 8.5 Tests (`test/core/ai/chat/security/services/security_monitor_test.dart`)
**Checkpoint 8 commit:** `feat(stage7e): Add security monitoring`

### Task 9: Integrate security into AI chat flow — ☐ pending
- [ ] 9.1 Register services in DI
- [ ] 9.2–9.4 Rate limiting in chat endpoint (check/handle/record)
- [ ] 9.5–9.7 Input validation (validate/handle/sanitize)
- [ ] 9.8–9.9 Log redaction wrapper
- [ ] 9.10–9.12 Authentication on chat/admin endpoints
- [ ] 9.13–9.15 Security event logging
- [ ] 9.16–9.20 Integration tests
**Checkpoint 9 commit:** `feat(stage7e): Integrate security into AI chat flow`

### Task 10: Property tests & docs — ☐ pending
- [ ] 10.1–10.10 Property-based tests (rate limits, redaction, validation, HTTPS, auth, admin, monitoring)
- [ ] 10.11 Manual test scenarios doc (`docs/modules/ai/STAGE_7E_MANUAL_TEST_SCENARIOS.md`)
- [ ] 10.12 Stage 7e doc (`docs/modules/ai/STAGE_7E_PRIVACY_SECURITY.md`)
- [ ] 10.13 Update LLM Stages Overview
**Checkpoint 10 commit:** `feat(stage7e): Complete Stage 7e - Privacy & Security`

## Stage 7e Completion Criteria
- [ ] All task groups done (1–10) with subtasks checked
- [ ] All unit/property/integration tests passing
- [ ] Security/manual testing validated
- [ ] Docs updated
- [ ] All changes committed
