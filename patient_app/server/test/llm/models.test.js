import test from 'node:test';
import assert from 'node:assert';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

import { loadModelCatalog } from '../../src/llm/models.js';

function writeTempConfig(content) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'models-'));
  const file = path.join(dir, 'models.json');
  fs.writeFileSync(file, content, 'utf-8');
  return file;
}

test('loads valid model config', () => {
  const file = writeTempConfig(
    JSON.stringify({
      chatFriendly: 'my/friendly',
      chatReasoning: 'my/reasoning',
      chatFallback: 'my/fallback',
      image: 'my/image',
    }),
  );

  const catalog = loadModelCatalog(file);
  assert.strictEqual(catalog.chatFriendly, 'my/friendly');
  assert.strictEqual(catalog.chatReasoning, 'my/reasoning');
  assert.strictEqual(catalog.chatFallback, 'my/fallback');
  assert.strictEqual(catalog.image, 'my/image');
});

test('throws on missing required keys', () => {
  const file = writeTempConfig(
    JSON.stringify({
      chatFriendly: 'my/friendly',
      chatReasoning: 'my/reasoning',
      chatFallback: 'my/fallback',
    }),
  );

  assert.throws(() => loadModelCatalog(file), /missing required keys: image/);
});

test('throws on invalid JSON', () => {
  const file = writeTempConfig('{not-json}');
  assert.throws(() => loadModelCatalog(file), /Invalid JSON/);
});

test('throws when file is missing', () => {
  const missingPath = path.join(os.tmpdir(), 'nonexistent-models.json');
  assert.throws(() => loadModelCatalog(missingPath), /Failed to read models config/);
});
