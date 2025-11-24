import assert from 'node:assert';
import { countTokens } from '../src/llm/token_counter.js';

const result = countTokens({
  systemPrompt: 'You are helpful.',
  history: [
    { role: 'user', content: 'Hi' },
    { role: 'assistant', content: 'Hello' },
  ],
  userMessage: 'What now?',
  model: 'openai/gpt-oss-20b',
});

assert(result.total > 0);
assert(result.systemPromptTokens > 0);
assert(result.historyTokens > 0);
assert(result.userTokens > 0);
