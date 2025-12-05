import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const MODEL_CONFIG_PATH = path.join(__dirname, '..', '..', 'config', 'models.json');

const DEFAULT_MODEL_CATALOG = {
  chatFriendly: 'google/gemma-3n-E4B-it',
  chatReasoning: 'ServiceNow-AI/Apriel-1.5-15b-Thinker',
  // Fallback chat model (OSS via Together)
  chatFallback: 'openai/gpt-oss-20b',
  image: 'ServiceNow-AI/Apriel-1.5-15b-Thinker',
};

function loadModelCatalog() {
  try {
    const raw = fs.readFileSync(MODEL_CONFIG_PATH, 'utf-8');
    const parsed = JSON.parse(raw);
    // Merge to ensure any missing keys use safe defaults.
    return { ...DEFAULT_MODEL_CATALOG, ...parsed };
  } catch (_) {
    return DEFAULT_MODEL_CATALOG;
  }
}

export const MODEL_CATALOG = loadModelCatalog();

export function resolveChatModel(envModel) {
  if (envModel && envModel.trim().length > 0) {
    return envModel.trim();
  }
  // Default to friendly chat model; reasoning model can be selected explicitly or via env override.
  return MODEL_CATALOG.chatFriendly;
}
