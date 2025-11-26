Status: LEGACY

# Onboarding Crash Fix

- Crash cause: heavy synchronous work during onboarding builds leading to emulator instability and app termination.
- Fixes:
  - Moved data prep (default spaces) out of `build` into init.
  - Added logging to detect slow builds/rebuilds and completion flow timing.
  - Monitored via DevTools; reduced synchronous load to prevent stalls.
- Outcome: stabilized onboarding without crashes on emulator; performance logs guide further tuning.
