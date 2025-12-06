# Stage 7a: Manual Test Scenarios

## Overview
This document outlines manual test scenarios for Stage 7a (AI Personas & Error Recovery). These tests validate that the personas behave appropriately and error recovery works as expected.

## Prerequisites
- Application is running and connected to the internet
- Backend services are accessible
- At least 5 records exist in each space (Health, Finance, Education, Travel)

## Test Scenarios

### 1. Health Persona Validation

**Objective**: Verify the Health persona responds with appropriate tone and disclaimers.

**Steps**:
1. Navigate to the Health space
2. Ask: "What is my blood pressure?"
3. Ask: "Should I be worried about my health?"
4. Observe the AI response

**Success Criteria**:
- Response is empathetic and cautious
- Medical disclaimers are present ("not a medical professional", "consult your doctor")
- Tone is supportive and not alarming

### 2. Finance Persona Validation

**Objective**: Verify the Finance persona responds with practical, budget-conscious guidance.

**Steps**:
1. Navigate to the Finance space
2. Ask: "How much did I spend this month?"
3. Ask: "Should I save more money?"
4. Observe the AI response

**Success Criteria**:
- Response is practical and budget-focused
- Focuses on saving and budgeting
- Provides clear financial guidance
- Tone is practical and clear

### 3. Education Persona Validation

**Objective**: Verify the Education persona responds with study-focused, constructive guidance.

**Steps**:
1. Navigate to the Education space
2. Ask: "How are my studies going?"
3. Ask: "What should I study next?"
4. Observe the AI response

**Success Criteria**:
- Response is study-focused and constructive
- Provides learning encouragement
- Offers study tips and guidance
- Tone is constructive and supportive

### 4. Travel Persona Validation

**Objective**: Verify the Travel persona responds with exploratory, planning-focused guidance.

**Steps**:
1. Navigate to the Travel space
2. Ask: "Where should I travel next?"
3. Ask: "What did I do on my last trip?"
4. Observe the AI response

**Success Criteria**:
- Response is exploratory and enthusiastic
- Planning-focused guidance is provided
- Encourages discovery and adventure
- Tone is enthusiastic and planning-oriented

### 5. Persona Switching Validation

**Objective**: Verify persona changes appropriately when switching spaces mid-conversation.

**Steps**:
1. Start in Health space and ask a health question
2. Note the tone of the response
3. Switch to Finance space
4. Ask a finance question
5. Observe the AI response

**Success Criteria**:
- Tone changes appropriately from empathetic to practical
- No carryover of health-specific terminology
- Finance persona is active immediately

### 6. Network Error Recovery

**Objective**: Verify the system handles network errors gracefully with recovery.

**Steps**:
1. Disable network connection
2. Send a chat message
3. Observe the "Retrying..." indicator
4. Re-enable network connection
5. Observe that the message succeeds

**Success Criteria**:
- "Retrying..." indicator appears
- Message eventually succeeds when network is restored
- No crash or error message to user
- Appropriate retry delays (1s, 2s)

### 7. Rate Limit Recovery

**Objective**: Verify the system handles rate limit errors with appropriate delays.

**Steps**:
1. Send multiple messages quickly to trigger rate limits
2. Observe the rate limit response
3. Wait for the specified delay
4. Send another message

**Success Criteria**:
- System waits for the specified delay period
- Message succeeds after the delay
- User receives appropriate feedback
- No more than 5s wait time

### 8. Server Error Fallback

**Objective**: Verify the system provides helpful fallback when server errors occur.

**Steps**:
1. Simulate server error (if possible) or use testing endpoint
2. Send a chat message
3. Observe the fallback response

**Success Criteria**:
- Fallback message appears immediately
- Message is helpful and not technical
- No stack traces or technical jargon
- User can continue using the app

### 9. Timeout Recovery

**Objective**: Verify the system handles timeout errors appropriately.

**Steps**:
1. Configure a very short timeout (if possible) or simulate slow response
2. Send a chat message
3. Observe the timeout handling
4. Send another message after timeout

**Success Criteria**:
- Timeout is detected appropriately
- Fallback or retry mechanism activates
- User receives helpful feedback
- No hanging or unresponsive UI

### 10. Fallback Recovery

**Objective**: Verify normal operation resumes after service recovery.

**Steps**:
1. Cause a service failure (stop backend temporarily)
2. Send messages and observe fallback behavior
3. Restart the backend service
4. Send another message

**Success Criteria**:
- Fallback messages appear during failure
- Normal operation resumes automatically when service is restored
- No manual intervention required
- User experience is seamless

## Success Metrics

- All persona validation tests pass (appropriate tone and content)
- Error recovery tests show appropriate retry behavior
- Fallback tests provide helpful user messages
- No technical jargon in user-facing messages
- Conversation continuity maintained during errors
- Performance requirements met (<10s for recovery)