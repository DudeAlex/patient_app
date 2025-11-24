import assert from 'node:assert';
import { SYSTEM_PROMPT_TEMPLATE } from '../src/llm/prompt_template.js';

assert(SYSTEM_PROMPT_TEMPLATE.includes('{history}'));
assert(SYSTEM_PROMPT_TEMPLATE.includes('{user_message}'));
