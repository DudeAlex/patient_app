
import assert from 'assert/strict';
import { describe, it, before, after } from 'node:test';

// Configuration
const BASE_URL = 'http://localhost:3030/api/v1/chat';
// Match the valid token logic from user's AuthenticationService (len > 10)
const VALID_TOKEN = 'Bearer ' + 'x'.repeat(20);
const INVALID_TOKEN = 'Bearer short';

async function post(endpoint, body, token) {
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = token;

    const res = await fetch(`${BASE_URL}${endpoint}`, {
        method: 'POST',
        headers,
        body: JSON.stringify(body),
    });

    let data;
    try {
        data = await res.json();
    } catch {
        data = null;
    }

    return { status: res.status, data };
}

describe('Stage 7e Security Verification', () => {

    describe('Authentication', () => {
        it('should reject request without token (401)', async () => {
            const { status } = await post('/echo', { message: 'hello', threadId: '1' });
            assert.equal(status, 401, 'Should fail without token');
        });

        it('should reject request with invalid/short token (401)', async () => {
            const { status } = await post('/echo', { message: 'hello', threadId: '1' }, INVALID_TOKEN);
            assert.equal(status, 401, 'Should fail with short token');
        });

        it('should accept request with valid token (200)', async () => {
            const { status } = await post('/echo', { message: 'hello', threadId: '1' }, VALID_TOKEN);
            assert.equal(status, 200, 'Should pass with valid token');
        });
    });

    describe('Input Validation', () => {
        it('should reject empty message (400)', async () => {
            const { status } = await post('/echo', { message: '', threadId: '1' }, VALID_TOKEN);
            assert.equal(status, 400);
        });

        it('should reject whitespace-only message (400)', async () => {
            const { status } = await post('/echo', { message: '   ', threadId: '1' }, VALID_TOKEN);
            assert.equal(status, 400);
        });

        it('should reject <script> tags (400)', async () => {
            const { status, data } = await post('/echo', { message: '<script>alert(1)</script>', threadId: '1' }, VALID_TOKEN);
            assert.equal(status, 400);
            assert.match(data.error.message, /malicious/i);
        });

        it('should reject javascript: protocol (400)', async () => {
            const { status } = await post('/echo', { message: 'javascript:alert(1)', threadId: '1' }, VALID_TOKEN);
            assert.equal(status, 400);
        });
    });

    describe('Data Redaction', () => {
        it('should redact email addresses in echo response', async () => {
            const email = 'test@example.com';
            const { status, data } = await post('/echo', { message: `My email is ${email}`, threadId: '1' }, VALID_TOKEN);
            assert.equal(status, 200);
            assert.match(data.message, /\[REDACTED\]/);
            assert.ok(!data.message.includes(email), 'Email should not be present');
        });

        it('should redact phone numbers in echo response', async () => {
            const phone = '123-456-7890';
            const { status, data } = await post('/echo', { message: `Call me at ${phone}`, threadId: '1' }, VALID_TOKEN);
            assert.equal(status, 200);
            assert.match(data.message, /\[REDACTED\]/);
            assert.ok(!data.message.includes(phone), 'Phone should not be present');
        });
    });

});
