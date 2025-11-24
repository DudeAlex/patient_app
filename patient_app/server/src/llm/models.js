export const MODEL_CATALOG = {
  chatFriendly: 'gemma-3n-e4b-it',
  chatReasoning: 'ServiceNow-AI/Apriel-1.5-15b-Thinker',
  // Fallback chat model (OSS via Together)
  chatFallback: 'openai/gpt-oss-20b',
  image: 'ServiceNow-AI/Apriel-1.5-15b-Thinker',
};

export function resolveChatModel(envModel) {
  if (envModel && envModel.trim().length > 0) {
    return envModel.trim();
  }
  // Default to friendly chat model; reasoning model can be selected explicitly or via env override.
  return MODEL_CATALOG.chatFriendly;
}
