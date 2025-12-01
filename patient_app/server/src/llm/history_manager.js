const MAX_HISTORY = 3;

/**
 * Formats conversation history for the LLM prompt.
 * - Limits to the last 3 turns (oldest to newest)
 * - Preserves role/content structure
 * - Handles empty history gracefully
 *
 * @param {Array<{role: 'user'|'assistant', content: string}>} history
 * @returns {Array<{role: string, content: string}>}
 */
export function formatHistory(history = []) {
  if (!Array.isArray(history) || history.length === 0) {
    return [];
  }
  const trimmed = history
    .filter((m) => m?.content?.trim())
    .slice(-MAX_HISTORY);
  return trimmed.map((message) => ({
    role: message.role === 'assistant' ? 'assistant' : 'user',
    content: message.content.trim(),
  }));
}

export { MAX_HISTORY };
