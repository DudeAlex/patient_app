# Stage 7a: Manual Testing Scenarios

## Overview
This document outlines the manual testing scenarios for Stage 7a (AI Personas & Error Recovery). These tests should be executed to validate the persona system and error recovery capabilities.

## How to Test
1. Create test data in each Space (Health, Finance, Education, Travel)
2. Interact with the AI in each Space to validate persona behavior
3. Simulate various error conditions to validate recovery mechanisms
4. Document results and any issues found

## Success Criteria
- AI adapts tone and guidance based on active Space
- Error recovery works automatically without user intervention
- Fallback responses are helpful and user-friendly
- No technical jargon is exposed to users
- Recovery completes within performance requirements

---

## Persona Test Scenarios

### Health Persona Test
**Objective:** Validate empathetic, cautious health companion persona

**Steps:**
1. Navigate to Health Space
2. Create 3-5 health-related records (blood pressure, medications, appointments)
3. Ask: "How is my blood pressure looking?"
4. Ask: "Should I be concerned about my health?"
5. Ask: "What should I discuss with my doctor?"

**Expected Results:**
- Responses are empathetic and cautious
- Medical disclaimers are included
- Encourages consulting healthcare professionals
- Tone is supportive and caring

### Finance Persona Test
**Objective:** Validate practical, budget-conscious finance advisor persona

**Steps:**
1. Navigate to Finance Space
2. Create 3-5 finance-related records (expenses, income, budget items)
3. Ask: "How much did I spend this month?"
4. Ask: "Should I save more money?"
5. Ask: "What's my budget status?"

**Expected Results:**
- Responses focus on budgeting and saving
- Practical money management tips provided
- Clear, actionable financial guidance
- Tone is practical and budget-conscious

### Education Persona Test
**Objective:** Validate study-focused, constructive education mentor persona

**Steps:**
1. Navigate to Education Space
2. Create 3-5 education-related records (study sessions, notes, assignments)
3. Ask: "How are my studies going?"
4. Ask: "What should I study next?"
5. Ask: "Can you help me with learning tips?"

**Expected Results:**
- Responses encourage learning and study techniques
- Constructive feedback provided
- Study tips and guidance offered
- Tone is supportive and education-focused

### Travel Persona Test
**Objective:** Validate exploratory, planning-focused travel planner persona

**Steps:**
1. Navigate to Travel Space
2. Create 3-5 travel-related records (trips, plans, destinations)
3. Ask: "Where should I travel next?"
4. Ask: "What did I do on my last trip?"
5. Ask: "Can you help me plan a trip?"

**Expected Results:**
- Responses are enthusiastic about exploration
- Planning-focused guidance provided
- Suggestions for destinations and activities
- Tone is exploratory and travel-oriented

### Persona Switching Test
**Objective:** Validate persona changes when switching Spaces mid-conversation

**Steps:**
1. Start conversation in Health Space
2. Ask a health question and note the tone
3. Switch to Finance Space
4. Ask a finance question
5. Verify tone changed appropriately
6. Switch back to Health Space
7. Verify tone changed back

**Expected Results:**
- AI adapts persona immediately after Space switch
- Tone and guidance match new Space context
- Conversation remains coherent despite persona change

---

## Error Recovery Test Scenarios

### Network Error Recovery Test
**Objective:** Validate automatic recovery from network connectivity issues

**Steps:**
1. Ensure device has internet connectivity
2. Start sending a message to AI
3. Disconnect from internet (or simulate network issue)
4. Observe retry behavior in UI
5. Reconnect to internet
6. Verify message eventually succeeds

**Expected Results:**
- "Retrying..." indicator appears
- System automatically retries after connection restored
- Message succeeds without user intervention
- No error message shown to user during retry

### Rate Limit Recovery Test
**Objective:** Validate handling of API rate limit errors

**Steps:**
1. Send multiple rapid requests to trigger rate limiting
2. Observe system behavior when rate limit hit
3. Wait for rate limit to reset
4. Send another request

**Expected Results:**
- System waits for specified delay before retrying
- Delay does not exceed 5 seconds
- Eventually succeeds when rate limit resets
- User-friendly message if delay is significant

### Timeout Recovery Test
**Objective:** Validate handling of request timeout errors

**Steps:**
1. Send a complex request that might timeout
2. Observe system behavior when timeout occurs
3. Send a simpler version of the same request

**Expected Results:**
- System retries with shorter timeout
- Eventually succeeds or falls back gracefully
- User-friendly timeout message if needed
- No crash or hang

### Server Error Recovery Test
**Objective:** Validate immediate fallback when server is unavailable

**Steps:**
1. Stop backend server (if possible in test environment)
2. Send a message to AI
3. Observe fallback response
4. Restart backend server
5. Send another message

**Expected Results:**
- Immediate fallback response without retry attempts
- Helpful user-friendly message provided
- Normal operation resumes after server restart
- No crash or data loss

### Complete Service Failure Test
**Objective:** Validate fallback behavior when all recovery attempts fail

**Steps:**
1. Simulate complete service unavailability
2. Send multiple messages
3. Verify fallback responses
4. Restore service availability
5. Verify normal operation resumes

**Expected Results:**
- All requests return helpful fallback responses
- No exceptions or crashes
- Conversation can continue in limited mode
- Full functionality restored when service returns

---

## Fallback Behavior Validation

### Fallback Message Quality
**Objective:** Validate that fallback messages are user-friendly and helpful

**Steps:**
1. Trigger various error conditions
2. Collect fallback messages for each error type
3. Review messages for technical jargon
4. Verify helpfulness and clarity

**Expected Results:**
- No technical jargon (no stack traces, error codes, etc.)
- Clear, actionable guidance provided
- Messages appropriate for the error type
- Maintains conversation continuity

### Fallback Recovery
**Objective:** Validate that system returns to normal operation after fallback

**Steps:**
1. Cause system to enter fallback mode
2. Note fallback behavior
3. Restore normal service conditions
4. Send new messages

**Expected Results:**
- System automatically detects service restoration
- Normal AI responses resume without user action
- No manual intervention required
- Conversation can continue normally

---

## Performance Validation

### Recovery Time Bounds
**Objective:** Validate that recovery completes within time limits

**Steps:**
1. Trigger error recovery scenarios
2. Measure time from error to resolution/fallback
3. Verify within performance requirements

**Expected Results:**
- Total recovery time < 10 seconds
- Individual attempts timeout after 30 seconds
- No blocking of UI thread during recovery

---

## Documentation Notes
- Record any issues found during testing
- Note any improvements needed for user experience
- Document edge cases or unexpected behaviors
- Validate all requirements from design document