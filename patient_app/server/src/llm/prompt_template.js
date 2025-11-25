export const SYSTEM_PROMPT_VERSION = 'v1.1';

// Builds the system prompt for Stage 3 with space metadata and record summaries.
export function buildPrompt({
  spaceName,
  spaceDescription,
  categories = [],
  recordSummaries = [],
  historyText,
  userMessage,
}) {
  const formattedCategories =
    categories.length === 0 ? 'None' : categories.join(', ');
  const formattedRecords = formatRecordSummaries(recordSummaries);

  return `
You are the Universal Life Companion: a concise, compassionate assistant that helps users organize and reflect on their personal information. You are safety-first, privacy-conscious, and honest about uncertainty.

Active Space: ${spaceName || 'Unknown'}
Space Description: ${spaceDescription || 'No description provided.'}
Categories: ${formattedCategories}

Recent Records:
${formattedRecords}

Guidelines:
- Keep replies short, clear, and actionable (aim for <= 80 words).
- Be empathetic and encouraging without overstepping into medical or legal advice.
- Ground responses strictly in the provided records and history; if missing info, say what you need.
- Avoid fabricating details; acknowledge uncertainty explicitly.
- Respect privacy: do not request sensitive identifiers unless essential to help.
- Offer at most 2-3 specific next steps when appropriate.

Conversation history (oldest to newest):
${historyText}

User message:
${userMessage}

Respond with a concise answer that follows the guidelines above.
`.trim();
}

export function formatRecordSummaries(records = []) {
  if (!Array.isArray(records) || records.length === 0) {
    return 'None';
  }
  return records
    .map((record, index) => {
      const title = record.title || 'Untitled';
      const type = record.type || 'unknown';
      const date = record.date || record.createdAt || 'unknown date';
      const tags = Array.isArray(record.tags) && record.tags.length > 0 ? record.tags.join(', ') : 'none';
      const summary = record.summary || '';
      return `${index + 1}. ${title} (${type}) - Date: ${date} - Tags: [${tags}]${summary ? ` - Summary: ${summary}` : ''}`;
    })
    .join('\n');
}
