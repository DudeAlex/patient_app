export const MODEL_CATALOG = {
  chatFriendly: 'gemma-3n-e4b-it',
  chatReasoning: 'ServiceNow-AI/Apriel-1.5-15b-Thinker',
  // Together no longer supports the old Meta-Llama-3-70B-Instruct-Turbo id; use supported chat fallback.
  chatFallback: 'meta-llama/Llama-3-70b-chat-hf',
  image: 'ServiceNow-AI/Apriel-1.5-15b-Thinker',
};

export function resolveChatModel(envModel) {
  if (envModel && envModel.trim().length > 0) {
    return envModel.trim();
  }
  // Default to friendly chat model; reasoning model can be selected explicitly or via env override.
  return MODEL_CATALOG.chatFriendly;
}
