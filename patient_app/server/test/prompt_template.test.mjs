import assert from 'node:assert';
import { buildPrompt, formatRecordSummaries } from '../src/llm/prompt_template.js';

const prompt = buildPrompt({
  spaceName: 'Health',
  spaceDescription: 'Health records',
  categories: ['visits', 'labs'],
  recordSummaries: [
    { title: 'Visit', type: 'visit', date: '2025-01-01', tags: ['checkup'], summary: 'Follow-up' },
  ],
  historyText: 'user: hi',
  userMessage: 'Need help',
});

assert(prompt.includes('Active Space: Health'));
assert(prompt.includes('Categories: visits, labs'));
assert(formatRecordSummaries([]) === 'None');
assert(formatRecordSummaries([{ title: 'A', type: 't', tags: [], summary: '', date: '2025-01-01' }]).includes('1.'));
