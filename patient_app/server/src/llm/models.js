export const MODEL_CATALOG = {
  chatPrimary: 'ServiceNow-AI/Apriel-1.5-15b-Thinker',
  chatFallback: 'meta-llama/Meta-Llama-3-70B-Instruct-Turbo',
  image: 'black-forest-labs/FLUX-1-schnell',
};

export function resolveChatModel(envModel) {
  if (envModel && envModel.trim().length > 0) {
    return envModel.trim();
  }
  return MODEL_CATALOG.chatPrimary;
}
