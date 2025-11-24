import assert from 'node:assert';
import { resolveChatModel, MODEL_CATALOG } from '../src/llm/models.js';

assert.strictEqual(resolveChatModel('custom/model'), 'custom/model');
assert.strictEqual(resolveChatModel(''), MODEL_CATALOG.chatFriendly);
