import assert from 'node:assert';
import { formatHistory, MAX_HISTORY } from '../src/llm/history_manager.js';

const histories = Array.from({ length: 10 }, (_, i) =>
  Array.from({ length: i + 1 }, (__, j) => ({
    role: j % 2 === 0 ? 'user' : 'assistant',
    content: `msg-${i}-${j}`,
  })),
);

for (const history of histories) {
  const formatted = formatHistory(history);
  assert(formatted.length <= MAX_HISTORY);
  if (history.length > 0) {
    const expectedLast = history.slice(-1)[0].content;
    assert.strictEqual(formatted.slice(-1)[0].content, expectedLast);
  }
}
