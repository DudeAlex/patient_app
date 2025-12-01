import assert from 'node:assert';
import { formatHistory, MAX_HISTORY } from '../src/llm/history_manager.js';

{
  const input = [
    { role: 'user', content: 'old1' },
    { role: 'assistant', content: 'old2' },
    { role: 'user', content: 'old3' },
    { role: 'assistant', content: 'newest' },
  ];
  const result = formatHistory(input);
  assert.strictEqual(result.length, MAX_HISTORY);
  assert.strictEqual(result[0].content, 'old2');
  assert.strictEqual(result[1].role, 'user');
  assert.strictEqual(result[2].role, 'assistant');
}

{
  const result = formatHistory([{ role: 'user', content: 'hi' }, { role: 'assistant', content: '' }]);
  assert.strictEqual(result.length, 1);
  assert.strictEqual(result[0].content, 'hi');
}

assert.deepStrictEqual(formatHistory([]), []);
assert.deepStrictEqual(formatHistory(null), []);
