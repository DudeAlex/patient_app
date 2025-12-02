export const SYSTEM_PROMPT_VERSION = 'v1.2-stage4';

// Builds the system prompt for Stage 4 with optimized context and filtering metadata.
export function buildPrompt({
  spaceName,
  spaceDescription,
  categories = [],
  recordSummaries = [],
  historyText,
  userMessage,
  contextStats = null,
  filters = null,
  persona = null, // Added persona parameter
}) {
  const formattedCategories =
    categories.length === 0 ? 'None' : categories.join(', ');
  const formattedRecords = formatRecordSummaries(recordSummaries);
  const contextNotes = buildContextNotes(recordSummaries, contextStats, filters);
  const baseSystemPrompt = `You are the Universal Life Companion: a concise, compassionate assistant that helps users organize and reflect on their personal information. You are safety-first, privacy-conscious, and honest about uncertainty.`;
  const systemPrompt = persona ? persona.buildSystemPrompt(baseSystemPrompt) : baseSystemPrompt;

  return `${systemPrompt}

Active Space: ${spaceName || 'Unknown'} (${spaceDescription || 'No description provided.'})
Categories: ${formattedCategories}

Relevant Records (filtered by date and relevance):
${formattedRecords}

${contextNotes}

Guidelines:
- **ALWAYS respond in the same language as the user's message.** If the user writes in Russian, respond in Russian. If in Arabic, respond in Arabic. Match the user's language exactly.
- Keep replies short, clear, and actionable (aim for <= 80 words).
- Be empathetic and encouraging without overstepping into medical or legal advice.
- Ground responses strictly in the provided records and history; if missing info, say what you need.
- Acknowledge if information might be incomplete due to date filtering or record limits.
- Suggest exploring other time periods if the user's question might relate to older records.
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

// Builds context notes section with filtering information
function buildContextNotes(recordSummaries, contextStats, filters) {
  const parts = [];
  
  // Record count information
  if (contextStats) {
    const included = contextStats.recordsIncluded || recordSummaries.length;
    const total = contextStats.recordsFiltered || included;
    parts.push(`- Showing ${included} of ${total} records`);
  } else if (recordSummaries.length > 0) {
    parts.push(`- Showing ${recordSummaries.length} recent records`);
  }
  
  // Date range information
  if (filters && filters.dateRange) {
    const days = calculateDayRange(filters.dateRange);
    if (days) {
      parts.push(`- Date range: last ${days} days`);
    }
  }
  
  // Acknowledgment about exclusions
  if (contextStats && contextStats.recordsFiltered > contextStats.recordsIncluded) {
    parts.push('- Older or less relevant records may be excluded');
  }
  
  if (parts.length === 0) {
    return '';
  }
  
  return `Context Notes:\n${parts.join('\n')}`;
}

// Calculate day range from dateRange filter
function calculateDayRange(dateRange) {
  if (!dateRange || !dateRange.start || !dateRange.end) {
    return null;
  }
  
  try {
    const start = new Date(dateRange.start);
    const end = new Date(dateRange.end);
    const diffMs = end - start;
    const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24));
    return diffDays > 0 ? diffDays : null;
  } catch (e) {
    return null;
  }
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
