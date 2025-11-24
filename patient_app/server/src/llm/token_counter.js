import { encoding_for_model } from '@dqbd/tiktoken';
import { resolveChatModel } from './models.js';

const DEFAULT_MODEL = resolveChatModel(process.env.TOGETHER_MODEL);

function getEncoder(model) {
  try {
    return encoding_for_model(model);
  } catch (_) {
    // Fallback to a common encoding if model is unknown to tiktoken package.
    return encoding_for_model('gpt-3.5-turbo');
  }
}

export function countTokens({ model = DEFAULT_MODEL, systemPrompt = '', history = [], userMessage = '' } = {}) {
  const encoder = getEncoder(model);

  const encodeText = (text) => encoder.encode(text || '').length;

  const historyTokens = history.reduce((sum, msg) => {
    const content = `${msg.role || 'user'}: ${msg.content || ''}`;
    return sum + encodeText(content);
  }, 0);

  const total =
    encodeText(systemPrompt) +
    historyTokens +
    encodeText(userMessage);

  return {
    model,
    systemPromptTokens: encodeText(systemPrompt),
    historyTokens,
    userTokens: encodeText(userMessage),
    total,
  };
}
