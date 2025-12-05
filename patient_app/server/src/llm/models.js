import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const MODEL_CONFIG_PATH =
  process.env.MODEL_CONFIG_PATH ||
  path.join(__dirname, '..', '..', 'config', 'models.json');
const REQUIRED_KEYS = ['chatFriendly', 'chatReasoning', 'chatFallback', 'image'];

export function loadModelCatalog(configPath = MODEL_CONFIG_PATH) {
  let raw;
  try {
    raw = fs.readFileSync(configPath, 'utf-8');
  } catch (err) {
    throw new Error(`Failed to read models config at ${configPath}: ${err.message}`);
  }

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (err) {
    throw new Error(`Invalid JSON in models config at ${configPath}: ${err.message}`);
  }

  if (!parsed || typeof parsed !== 'object') {
    throw new Error(`models config at ${configPath} must be an object`);
  }

  const missing = REQUIRED_KEYS.filter(
    (key) => typeof parsed[key] !== 'string' || parsed[key].trim().length === 0,
  );
  if (missing.length > 0) {
    throw new Error(`models config missing required keys: ${missing.join(', ')}`);
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
