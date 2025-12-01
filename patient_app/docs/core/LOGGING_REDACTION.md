# Logging Redaction Configuration

## Overview

The logging system now supports environment-aware redaction of sensitive data. In development mode, all data is visible in logs for debugging. In production, sensitive data is automatically redacted for privacy compliance.

## How It Works

### Automatic Environment Detection

The system automatically detects the environment and enables/disables redaction:

- **Development/Debug Mode**: `enableRedaction = false` - All data visible
- **Production Mode**: `enableRedaction = true` - Sensitive data redacted

### Configuration

You can control redaction behavior in `assets/config/logging_config.json`:

```json
{
  "minLevel": "info",
  "consoleEnabled": true,
  "fileEnabled": true,
  "maxFileSize": 5242880,
  "maxFiles": 5,
  "moduleFilters": ["*"],
  "moduleExcludes": [],
  "performanceThreshold": 1000,
  "enableRedaction": false
}
```

**Settings:**
- `enableRedaction: false` - Show all data (development)
- `enableRedaction: true` - Redact sensitive data (production)

### Environment Detection

The system checks two sources to determine if redaction should be enabled:

1. **Config file**: `logging_config.json` → `enableRedaction` field
2. **Environment variable**: `ENV` environment variable
   - If `ENV=prod` or `ENV=production`, redaction is enabled
   - Otherwise, redaction is disabled

**Priority**: Config file setting takes precedence over environment detection.

## What Gets Redacted

When redaction is enabled, the following data is automatically redacted:

### Sensitive Fields (in context maps):
- `email`
- `password`
- `token`, `accessToken`, `refreshToken`
- `title`, `text`, `notes`, `content`
- `name`, `displayName`
- `phone`, `phoneNumber`
- `address`
- `ssn`, `creditCard`

### Sensitive Patterns (in strings):
- Email addresses → `[EMAIL_REDACTED]`
- Long tokens (32+ chars) → `[TOKEN_REDACTED]`
- Phone numbers → `[PHONE_REDACTED]`

## Development vs Production

### Development Mode (Current)

```json
{
  "enableRedaction": false
}
```

**Logs show:**
```
Token budget allocated
  Context: {
    total: 4800,
    system: 800,
    context: 2000,
    history: 1000,
    response: 1000,
    tokensUsed: 2450
  }
```

### Production Mode

```json
{
  "enableRedaction": true
}
```

**Logs show:**
```
Token budget allocated
  Context: {
    total: 4800,
    system: 800,
    context: [REDACTED],
    history: 1000,
    response: 1000,
    tokensUsed: [REDACTED]
  }
```

## Switching to Production

When you're ready to deploy to production:

1. **Update logging config**:
   ```json
   {
     "enableRedaction": true
   }
   ```

2. **Or set environment variable**:
   ```bash
   flutter build apk --dart-define=ENV=prod
   ```

3. **Rebuild the app**:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

## Testing Redaction

To test redaction behavior in development:

1. **Enable redaction temporarily**:
   ```json
   {
     "enableRedaction": true
   }
   ```

2. **Hot restart the app**:
   ```bash
   r  # in flutter run terminal
   ```

3. **Check logs** - sensitive data should now show `[REDACTED]`

4. **Disable redaction** when done testing:
   ```json
   {
     "enableRedaction": false
   }
   ```

## Code Changes

### PrivacyFilter

```dart
class PrivacyFilter {
  final bool enableRedaction;

  PrivacyFilter({required this.enableRedaction});

  Map<String, dynamic> redact(Map<String, dynamic> data) {
    // Skip redaction in development mode
    if (!enableRedaction) {
      return data;
    }
    // ... redaction logic
  }
}
```

### LoggerService

```dart
LoggerService({
  required this.config,
  required this.environmentContext,
  required this.writers,
  PrivacyFilter? privacyFilter,
}) : privacyFilter = privacyFilter ?? PrivacyFilter(
      enableRedaction: config.enableRedaction || 
                      environmentContext.environment == 'prod' || 
                      environmentContext.environment == 'production',
    );
```

## Benefits

### Development
- ✅ Full visibility of all data for debugging
- ✅ See actual token counts, record IDs, user data
- ✅ Easier troubleshooting and performance analysis
- ✅ No need to guess what `[REDACTED]` values are

### Production
- ✅ Automatic privacy protection
- ✅ Compliance with data protection regulations
- ✅ No sensitive data in logs
- ✅ Safe to share logs with support teams

## Best Practices

1. **Always use `enableRedaction: false` in development**
   - Helps with debugging
   - Provides full visibility

2. **Always use `enableRedaction: true` in production**
   - Protects user privacy
   - Compliance requirement

3. **Test with redaction enabled before release**
   - Ensure logs are still useful
   - Verify no critical data is over-redacted

4. **Document what data you log**
   - Know what's being logged
   - Understand privacy implications

5. **Review logs regularly**
   - Check for accidentally logged sensitive data
   - Update redaction rules as needed

## Troubleshooting

### Logs still showing [REDACTED] in development

**Check:**
1. `assets/config/logging_config.json` → `enableRedaction` should be `false`
2. Hot restart the app (not just hot reload)
3. Verify config file is being loaded correctly

### Logs showing sensitive data in production

**Fix immediately:**
1. Set `enableRedaction: true` in config
2. Rebuild and redeploy the app
3. Review what data was exposed
4. Update privacy filter rules if needed

## Related Files

- `lib/core/diagnostics/services/privacy_filter.dart` - Redaction logic
- `lib/core/diagnostics/services/logger_service.dart` - Logger service
- `lib/core/diagnostics/models/log_config.dart` - Configuration model
- `assets/config/logging_config.json` - Configuration file

---

**Last Updated:** November 28, 2024
**Status:** Active - Use for all logging configuration


## AI Chat Message Logging

### What Gets Logged

The AI chat service now logs both user messages and AI responses:

**User Messages:**
```
Sending chat request
  Context: {
    correlationId: ...,
    threadId: ...,
    userMessage: "What are my recent health records?",  // Logged in dev
    messageLength: 34,
    ...
  }
```

**AI Responses:**
```
AI chat response received
  Context: {
    correlationId: ...,
    threadId: ...,
    responseContent: "Here are your health records...",  // Logged in dev
    responseLength: 245,
    actionHints: [...],
    ...
  }
```

### Development vs Production

**Development Mode** (`enableRedaction: false`):
- Full user message visible: `userMessage: "What are my recent health records?"`
- Full AI response visible: `responseContent: "Here are your health records..."`
- Perfect for debugging conversation flow

**Production Mode** (`enableRedaction: true`):
- User message redacted: `userMessage: [REDACTED]`
- AI response redacted: `responseContent: [REDACTED]`
- Privacy compliant

### Why This Matters

**For Debugging:**
- See exactly what users asked
- See exactly what AI responded
- Verify context is being used correctly
- Debug conversation quality issues

**For Privacy:**
- In production, no message content is logged
- Only metadata (length, timing, tokens) is recorded
- Compliant with privacy regulations

---

**Last Updated:** November 28, 2024
