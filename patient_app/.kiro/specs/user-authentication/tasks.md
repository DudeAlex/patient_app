# Implementation Plan

- [x] 1. Set up authentication module structure and core domain entities





  - Create directory structure under `lib/features/authentication/`
  - Implement `User` entity with email, password hash, MFA settings, and Google account linking
  - Implement `Session` entity with token, device info, and expiration tracking
  - Implement `AuthMethod` and `MfaMethod` enums
  - Implement `LoginAttempt` entity for audit logging
  - _Requirements: 1.1, 2.1, 3.1, 4.1, 5.1, 9.3_

- [x] 2. Implement domain value objects with validation





- [x] 2.1 Create Email value object


  - Implement email validation logic with regex pattern
  - Add error handling for invalid email formats
  - _Requirements: 1.1, 2.1, 6.1_

- [x] 2.2 Create Password value object


  - Implement password strength validation (8+ chars, uppercase, lowercase, number, special char)
  - Add error messages for each validation rule
  - _Requirements: 1.3_

- [x] 2.3 Create AuthToken value object


  - Implement secure token wrapper with expiration checking
  - Add token generation and validation methods
  - _Requirements: 2.5, 7.1_

- [x] 3. Define application ports (interfaces)





  - Create `AuthRepository` interface for data persistence
  - Create `BiometricGateway` interface for biometric authentication
  - Create `GoogleAuthGateway` interface for Google Sign-In
  - Create `EmailGateway` interface for sending emails
  - Create `SecureStorageGateway` interface for secure credential storage
  - _Requirements: All_

- [x] 4. Implement infrastructure services





- [x] 4.1 Create PasswordHasher service


  - Implement bcrypt hashing with cost factor 12
  - Add password verification method
  - _Requirements: 10.1_

- [x] 4.2 Create TokenGenerator service


  - Implement secure random token generation
  - Add AES-256 encryption for token storage
  - Implement token expiration logic (24-hour sessions)
  - _Requirements: 2.5, 10.2_

- [x] 4.3 Create OtpGenerator service


  - Implement 6-digit OTP generation
  - Add 5-minute expiration logic
  - Use cryptographically secure random number generation
  - _Requirements: 4.3_

- [x] 5. Implement database schema and repository





- [x] 5.1 Create database migration for authentication tables


  - Add `users` table with email, password_hash, MFA settings, Google account ID
  - Add `sessions` table with token, device info, expiration
  - Add `login_attempts` table for audit logging
  - Add `mfa_pending` table for temporary MFA state
  - Add appropriate indexes for performance
  - _Requirements: 1.1, 2.1, 7.1, 9.3_

- [x] 5.2 Implement LocalAuthRepository


  - Implement user CRUD operations
  - Implement session management methods
  - Implement login attempt tracking
  - Implement query methods for rate limiting checks
  - _Requirements: 1.1, 2.1, 2.4, 9.1, 9.3_

- [x] 6. Implement gateway adapters





- [x] 6.1 Create FlutterSecureStorageGateway



  - Wrap flutter_secure_storage package
  - Implement read/write/delete operations
  - _Requirements: 5.2, 10.4_

- [x] 6.2 Create LocalAuthBiometricGateway


  - Integrate local_auth package
  - Implement availability checking
  - Implement biometric authentication flow
  - Implement secure credential storage/retrieval
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 10.4_

- [x] 6.3 Create GoogleSignInGateway


  - Reuse existing GoogleAuthService from google_drive_backup package
  - Implement sign-in flow returning email and Google ID
  - Implement sign-out flow
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 6.4 Create SmtpEmailGateway


  - Integrate email sending package (mailer or similar)
  - Implement verification email template
  - Implement password reset email template
  - Implement MFA OTP email template
  - Implement security alert email template
  - _Requirements: 1.4, 4.3, 6.1, 9.5_

- [ ] 7. Implement registration use case
- [x] 7.1 Create RegisterUserUseCase





  - Validate email not already registered
  - Hash password with PasswordHasher
  - Create User entity
  - Save to repository
  - Generate verification token
  - Send verification email
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [ ]* 7.2 Write unit tests for RegisterUserUseCase
  - Test successful registration
  - Test duplicate email error
  - Test password validation
  - Test email sending
  - _Requirements: 1.1, 1.2, 1.3_
- [x] 8. Implement email/password login use case









- [ ] 8. Implement email/password login use case

- [x] 8.1 Create LoginWithEmailUseCase



  - Check rate limiting (5 attempts per minute, 3 consecutive failures)
  - Find user by email
  - Verify password hash
  - Check if MFA enabled
  - Create session if no MFA, or return pending MFA state
  - Record login attempt
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 4.4_

- [ ]* 8.2 Write unit tests for LoginWithEmailUseCase
  - Test successful login without MFA
  - Test invalid credentials error
  - Test account lockout after 3 failures
  - Test rate limiting
  - Test MFA required flow
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [x] 9. Implement Google Sign-In use case




- [x] 9.1 Create LoginWithGoogleUseCase


  - Initiate Google OAuth flow via GoogleAuthGateway
  - Find or create user by Google email
  - Link Google account to existing user if email matches
  - Create session
  - Record login attempt
  - _Requirements: 3.1, 3.2, 3.3, 3.5_

- [ ]* 9.2 Write unit tests for LoginWithGoogleUseCase
  - Test new user creation
  - Test existing user login
  - Test account linking
  - Test Google auth failure
  - _Requirements: 3.1, 3.2, 3.5_

- [ ] 10. Implement MFA use cases
- [ ] 10.1 Create EnableMfaUseCase
  - Verify current password
  - Update user MFA settings
  - Send confirmation email
  - _Requirements: 4.1, 8.2_

- [ ] 10.2 Create VerifyMfaUseCase
  - Support biometric verification via BiometricGateway
  - Support email OTP verification
  - Limit to 3 verification attempts
  - Create session on successful verification
  - _Requirements: 4.2, 4.3, 4.4, 4.5_

- [ ]* 10.3 Write unit tests for MFA use cases
  - Test MFA enablement
  - Test biometric verification
  - Test OTP verification
  - Test verification attempt limits
  - _Requirements: 4.1, 4.2, 4.3, 4.5_

- [ ] 11. Implement biometric authentication use case
- [ ] 11.1 Create LoginWithBiometricUseCase
  - Check biometric availability
  - Retrieve stored credentials from secure storage
  - Authenticate via BiometricGateway
  - Create session on success
  - Fall back to password after 3 failures
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 11.2 Create EnableBiometricUseCase
  - Verify current password
  - Store encrypted credentials in secure storage
  - Update user biometric settings
  - _Requirements: 5.2, 8.3_

- [ ]* 11.3 Write unit tests for biometric use cases
  - Test biometric login success
  - Test fallback to password
  - Test biometric enablement
  - Test 30-day password re-authentication requirement
  - _Requirements: 5.1, 5.3, 5.4, 5.5_

- [ ] 12. Implement password reset use case
- [ ] 12.1 Create ResetPasswordUseCase
  - Generate secure reset token with 1-hour expiration
  - Send reset email with link
  - Validate reset token
  - Update password hash
  - Invalidate all existing sessions
  - Send confirmation email
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ]* 12.2 Write unit tests for ResetPasswordUseCase
  - Test reset link generation
  - Test token expiration
  - Test password update
  - Test session invalidation
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 13. Implement session management use cases
- [ ] 13.1 Create RefreshSessionUseCase
  - Check session expiration
  - Update last activity timestamp
  - Handle inactivity timeout (15 minutes)
  - Handle background timeout (5 minutes)
  - _Requirements: 7.1, 7.2, 7.3_

- [ ] 13.2 Create LogoutUseCase
  - Invalidate current session
  - Clear cached credentials from secure storage
  - _Requirements: 7.4, 7.5_

- [ ] 13.3 Create ManageSessionsUseCase
  - List active sessions with device info
  - Terminate specific session remotely
  - Get login history
  - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [ ]* 13.4 Write unit tests for session management use cases
  - Test session refresh
  - Test inactivity timeout
  - Test logout
  - Test remote session termination
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 9.1, 9.2_

- [ ] 14. Implement authentication state management
  - Create AuthStateManager for app-wide authentication state
  - Implement state transitions (unauthenticated, authenticated, mfaPending)
  - Add session persistence and restoration on app launch
  - Integrate with app navigation to enforce authentication
  - _Requirements: 7.1, 7.2, 7.3_

- [ ] 15. Create login screen UI
- [ ] 15.1 Build login screen layout
  - Add email input field with validation
  - Add password input field with visibility toggle
  - Add "Forgot Password" link
  - Add "Sign in with Google" button
  - Add "Use Biometric" button (conditional on availability)
  - Add error message display area
  - _Requirements: 2.1, 2.2, 3.1, 5.1_

- [ ] 15.2 Wire login screen to use cases
  - Connect email/password login to LoginWithEmailUseCase
  - Connect Google button to LoginWithGoogleUseCase
  - Connect biometric button to LoginWithBiometricUseCase
  - Handle MFA required state transition
  - Display user-friendly error messages
  - _Requirements: 2.1, 2.2, 2.3, 3.1, 5.1_

- [ ] 16. Create registration screen UI
- [ ] 16.1 Build registration screen layout
  - Add email input field with validation
  - Add password input field with strength indicator
  - Add password confirmation field
  - Add terms acceptance checkbox
  - Add "Sign up with Google" option
  - _Requirements: 1.1, 1.3_

- [ ] 16.2 Wire registration screen to use case
  - Connect form to RegisterUserUseCase
  - Display real-time password strength feedback
  - Show email verification success message
  - Handle duplicate email error
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [ ] 17. Create MFA screens UI
- [ ] 17.1 Build MFA setup screen
  - Display MFA method selection (biometric, email OTP)
  - Show setup instructions
  - Add enable/disable toggle
  - _Requirements: 4.1, 8.2_

- [ ] 17.2 Build MFA verification screen
  - Add OTP input field (6 digits)
  - Add biometric prompt trigger
  - Display remaining attempts
  - Show resend OTP option
  - _Requirements: 4.2, 4.3, 4.4, 4.5_

- [ ] 17.3 Wire MFA screens to use cases
  - Connect setup to EnableMfaUseCase
  - Connect verification to VerifyMfaUseCase
  - Handle verification failures
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 18. Create password reset screen UI
  - Build password reset request screen with email input
  - Build password reset confirmation screen with new password input
  - Wire to ResetPasswordUseCase
  - Display success/error messages
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 19. Create authentication settings screen UI
- [ ] 19.1 Build settings screen layout
  - Add MFA enable/disable toggle
  - Add biometric enable/disable toggle
  - Add Google account link/unlink option
  - Add change password option
  - Add active sessions list
  - Add login history view
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 9.1, 9.2, 9.3_

- [ ] 19.2 Wire settings screen to use cases
  - Connect MFA toggle to EnableMfaUseCase
  - Connect biometric toggle to EnableBiometricUseCase
  - Connect session list to ManageSessionsUseCase
  - Require password verification for sensitive changes
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 9.1, 9.2_

- [ ] 20. Implement authentication module dependency injection
  - Create AuthModule with all dependencies
  - Register use cases with repositories and gateways
  - Register services (PasswordHasher, TokenGenerator, OtpGenerator)
  - Wire module into app initialization
  - _Requirements: All_

- [ ] 21. Integrate authentication with app navigation
  - Add authentication guard to protected routes
  - Redirect unauthenticated users to login screen
  - Handle session expiration during app use
  - Implement background/foreground re-authentication
  - _Requirements: 7.1, 7.2, 7.3_

- [ ] 22. Implement security monitoring and alerts
  - Add suspicious activity detection logic
  - Send security alert emails for unusual login patterns
  - Log all authentication events for audit
  - Implement IP-based rate limiting
  - _Requirements: 2.4, 9.5, 10.5_

- [ ]* 23. Write integration tests for authentication flows
  - Test complete registration and login flow
  - Test Google Sign-In integration
  - Test MFA flow end-to-end
  - Test biometric authentication flow
  - Test password reset flow
  - Test session management
  - _Requirements: All_

- [ ]* 24. Write widget tests for authentication screens
  - Test login screen interactions
  - Test registration screen validation
  - Test MFA screens
  - Test password reset screen
  - Test settings screen
  - _Requirements: All_

- [ ]* 25. Perform security audit
  - Verify password hashing implementation
  - Test rate limiting effectiveness
  - Verify token encryption
  - Test SQL injection prevention
  - Test XSS prevention
  - Verify HTTPS enforcement
  - _Requirements: 10.1, 10.2, 10.3, 10.5_

- [ ]* 26. Perform accessibility audit
  - Test with screen reader (TalkBack/VoiceOver)
  - Test keyboard navigation
  - Test with large text sizes
  - Test high contrast mode
  - Verify error announcements
  - _Requirements: All_

- [ ] 27. Update documentation
  - Add authentication feature to README
  - Document authentication API for developers
  - Add security best practices guide
  - Update TESTING.md with manual test scenarios
  - Document migration path for existing users
  - _Requirements: All_
