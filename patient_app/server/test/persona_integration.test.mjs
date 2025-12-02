import test from 'node:test';
import assert from 'node:assert';
import { buildPrompt } from '../src/llm/prompt_template.js';
import { PersonaManager } from '../src/llm/persona_manager.js';

// Create a test instance of PersonaManager
const personaManager = new PersonaManager();
await personaManager.loadPersonas();

test('Persona Integration - Health Space gets health persona', async (t) => {
  await t.test('should use health persona for health space', () => {
    const healthPersona = personaManager.getPersona('health');
    const prompt = buildPrompt({
      spaceName: 'Health',
      spaceDescription: 'Health records and information',
      userMessage: 'How is my blood pressure?',
      historyText: 'None',
      recordSummaries: [],
      persona: healthPersona,
    });

    // Check that the health persona's system prompt addition is included
    assert.ok(prompt.includes('Always remind users that you are not a medical professional'));
    assert.ok(prompt.includes('Be empathetic and cautious in your responses'));
    assert.ok(prompt.includes('Active Space: Health'));
  });
});

test('Persona Integration - Finance Space gets finance persona', async (t) => {
  await t.test('should use finance persona for finance space', () => {
    const financePersona = personaManager.getPersona('finance');
    const prompt = buildPrompt({
      spaceName: 'Finance',
      spaceDescription: 'Financial records and information',
      userMessage: 'How much did I spend this month?',
      historyText: 'None',
      recordSummaries: [],
      persona: financePersona,
    });

    // Check that the finance persona's system prompt addition is included
    assert.ok(prompt.includes('Focus on practical money management'));
    assert.ok(prompt.includes('Provide clear, actionable financial tips'));
    assert.ok(prompt.includes('Active Space: Finance'));
  });
});

test('Persona Integration - prompt includes persona additions', async (t) => {
  await t.test('should include persona-specific system prompt additions', () => {
    const healthPersona = personaManager.getPersona('health');
    const financePersona = personaManager.getPersona('finance');
    const educationPersona = personaManager.getPersona('education');
    const travelPersona = personaManager.getPersona('travel');
    const defaultPersona = personaManager.getPersona('nonexistent');

    const healthPrompt = buildPrompt({
      spaceName: 'Health',
      spaceDescription: 'Health records',
      userMessage: 'Test',
      historyText: 'None',
      recordSummaries: [],
      persona: healthPersona,
    });

    const financePrompt = buildPrompt({
      spaceName: 'Finance',
      spaceDescription: 'Finance records',
      userMessage: 'Test',
      historyText: 'None',
      recordSummaries: [],
      persona: financePersona,
    });

    const educationPrompt = buildPrompt({
      spaceName: 'Education',
      spaceDescription: 'Education records',
      userMessage: 'Test',
      historyText: 'None',
      recordSummaries: [],
      persona: educationPersona,
    });

    const travelPrompt = buildPrompt({
      spaceName: 'Travel',
      spaceDescription: 'Travel records',
      userMessage: 'Test',
      historyText: 'None',
      recordSummaries: [],
      persona: travelPersona,
    });

    const defaultPrompt = buildPrompt({
      spaceName: 'General',
      spaceDescription: 'General records',
      userMessage: 'Test',
      historyText: 'None',
      recordSummaries: [],
      persona: defaultPersona,
    });

    // Verify each prompt contains its persona-specific addition
    assert.ok(healthPrompt.includes('Always remind users that you are not a medical professional'));
    assert.ok(financePrompt.includes('Focus on practical money management'));
    assert.ok(educationPrompt.includes('Help with learning, study techniques'));
    assert.ok(travelPrompt.includes('Be enthusiastic about exploration and discovery'));
    assert.ok(defaultPrompt.includes('Be helpful, concise, and friendly'));
  });
});

test('Persona Integration - default behavior when no persona provided', async (t) => {
  await t.test('should use default system prompt when no persona is provided', () => {
    const promptWithoutPersona = buildPrompt({
      spaceName: 'Health',
      spaceDescription: 'Health records',
      userMessage: 'Test',
      historyText: 'None',
      recordSummaries: [],
      // No persona provided
    });

    // Should include the default system prompt
    assert.ok(promptWithoutPersona.includes('You are the Universal Life Companion'));
    assert.ok(promptWithoutPersona.includes('Active Space: Health'));
  });
});