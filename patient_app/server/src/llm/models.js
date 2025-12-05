import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const MODEL_CONFIG_PATH = path.join(__dirname, '..', '..', 'config', 'models.json');

function loadModelCatalog() {
  const raw = fs.readFileSync(MODEL_CONFIG_PATH, 'utf-8');
  const parsed = JSON.parse(raw);
  if (!parsed || typeof parsed !== 'object') {
    throw new Error('models.json must contain an object with model ids');
  }
  return parsed;
}

export const MODEL_CATALOG = loadModelCatalog();

export function resolveChatModel(envModel) {
  if (envModel && envModel.trim().length > 0) {
    return envModel.trim();
  }
  // Default to friendly chat model; reasoning model can be selected explicitly or via env override.
  return MODEL_CATALOG.chatFriendly;
}
