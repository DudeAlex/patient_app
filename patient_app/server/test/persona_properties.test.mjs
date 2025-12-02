import test from 'node:test';
import assert from 'node:assert/strict';
import { PersonaManager } from '../src/llm/persona_manager.js';
import { PromptTemplate } from '../src/llm/prompt_template.js';

// Mock configuration for testing
const mockConfig = {
  "health": {
    "name": "Health Companion",
    "tone": "empathetic, cautious, supportive",
    "guidelines": [
      "Always include medical disclaimers",
      "Encourage consulting healthcare professionals",
      "Be sensitive to health concerns",
      "Focus on wellness and prevention"
    ],
    "systemPromptAddition": "You are a health companion. Always remind users that you are not a medical professional and that they should consult with healthcare providers for medical advice. Be empathetic and cautious in your responses, focusing on wellness and prevention."
  },
  "finance": {
    "name": "Finance Advisor",
    "tone": "practical, budget-conscious, clear",
    "guidelines": [
      "Focus on budgeting and saving",
      "Provide practical money management tips",
      "Be clear about financial concepts",
      "Encourage responsible spending"
    ],
    "systemPromptAddition": "You are a finance advisor. Focus on practical money management, budgeting, and saving. Provide clear, actionable financial tips while encouraging responsible spending and saving habits."
  },
  "education": {
    "name": "Study Mentor",
    "tone": "study-focused, constructive, encouraging",
    "guidelines": [
      "Focus on learning and study techniques",
      "Provide study tips and guidance",
      "Be constructive in feedback",
      "Encourage learning goals"
    ],
    "systemPromptAddition": "You are a study mentor. Help with learning, study techniques, and academic goals. Provide constructive feedback and study tips while encouraging learning and growth."
  },
  "travel": {
    "name": "Travel Planner",
    "tone": "exploratory, enthusiastic, planning-focused",
    "guidelines": [
      "Be enthusiastic about exploration",
      "Focus on planning and logistics",
      "Suggest activities and destinations",
      "Consider budget and timing"
    ],
    "systemPromptAddition": "You are a travel planner. Be enthusiastic about exploration and discovery. Help with planning trips, suggesting destinations, activities, and logistics while considering budget and timing."
  },
  "default": {
    "name": "General Assistant",
    "tone": "helpful, concise, friendly",
    "guidelines": [
      "Be helpful and responsive",
      "Keep responses concise",
      "Maintain friendly tone",
      "Provide general guidance"
    ],
    "systemPromptAddition": "You are a general assistant. Be helpful, concise, and friendly in your responses. Provide general guidance and assistance with various topics."
  }
};

test('Property 1: Persona selection consistency - getPersona returns same persona for same Space', async (t) => {
  const personaManager = new PersonaManager();
  // Mock the loadPersonas method to use our test config
  personaManager.personas = mockConfig;
  
  await t.test('health persona is consistent', () => {
    const firstCall = personaManager.getPersona('health');
    const secondCall = personaManager.getPersona('health');
    const thirdCall = personaManager.getPersona('health');
    
    assert.deepStrictEqual(firstCall, secondCall, 'First and second calls should return same persona');
    assert.deepStrictEqual(secondCall, thirdCall, 'Second and third calls should return same persona');
    assert.strictEqual(firstCall.name, 'Health Companion');
  });
  
  await t.test('finance persona is consistent', () => {
    const firstCall = personaManager.getPersona('finance');
    const secondCall = personaManager.getPersona('finance');
    const thirdCall = personaManager.getPersona('finance');
    
    assert.deepStrictEqual(firstCall, secondCall, 'First and second calls should return same persona');
    assert.deepStrictEqual(secondCall, thirdCall, 'Second and third calls should return same persona');
    assert.strictEqual(firstCall.name, 'Finance Advisor');
  });
  
  await t.test('education persona is consistent', () => {
    const firstCall = personaManager.getPersona('education');
    const secondCall = personaManager.getPersona('education');
    const thirdCall = personaManager.getPersona('education');
    
    assert.deepStrictEqual(firstCall, secondCall, 'First and second calls should return same persona');
    assert.deepStrictEqual(secondCall, thirdCall, 'Second and third calls should return same persona');
    assert.strictEqual(firstCall.name, 'Study Mentor');
  });
  
  await t.test('travel persona is consistent', () => {
    const firstCall = personaManager.getPersona('travel');
    const secondCall = personaManager.getPersona('travel');
    const thirdCall = personaManager.getPersona('travel');
    
    assert.deepStrictEqual(firstCall, secondCall, 'First and second calls should return same persona');
    assert.deepStrictEqual(secondCall, thirdCall, 'Second and third calls should return same persona');
    assert.strictEqual(firstCall.name, 'Travel Planner');
  });
  
  await t.test('default persona for unknown space', () => {
    const firstCall = personaManager.getPersona('unknown');
    const secondCall = personaManager.getPersona('unknown');
    
    assert.deepStrictEqual(firstCall, secondCall, 'Default persona should be consistent');
    assert.strictEqual(firstCall.name, 'General Assistant');
  });
});

test('Property 2: Persona prompt inclusion - generated prompts include persona additions', async (t) => {
  const personaManager = new PersonaManager();
  // Mock the loadPersonas method to use our test config
  personaManager.personas = mockConfig;
  
  const promptTemplate = new PromptTemplate();
  
  await t.test('health prompt includes health addition', () => {
    const healthPersona = personaManager.getPersona('health');
    const basePrompt = "You are an AI assistant.";
    const fullPrompt = promptTemplate.buildPrompt(basePrompt, healthPersona.systemPromptAddition);
    
    assert.ok(fullPrompt.includes('health companion'), 'Prompt should include health persona addition');
    assert.ok(fullPrompt.includes('medical professional'), 'Prompt should include medical disclaimer');
    assert.ok(fullPrompt.includes(healthPersona.systemPromptAddition), 'Prompt should include the full persona addition');
  });
  
  await t.test('finance prompt includes finance addition', () => {
    const financePersona = personaManager.getPersona('finance');
    const basePrompt = "You are an AI assistant.";
    const fullPrompt = promptTemplate.buildPrompt(basePrompt, financePersona.systemPromptAddition);
    
    assert.ok(fullPrompt.includes('finance advisor'), 'Prompt should include finance persona addition');
    assert.ok(fullPrompt.includes('budgeting'), 'Prompt should include finance-specific guidance');
    assert.ok(fullPrompt.includes(financePersona.systemPromptAddition), 'Prompt should include the full persona addition');
  });
  
  await t.test('education prompt includes education addition', () => {
    const educationPersona = personaManager.getPersona('education');
    const basePrompt = "You are an AI assistant.";
    const fullPrompt = promptTemplate.buildPrompt(basePrompt, educationPersona.systemPromptAddition);
    
    assert.ok(fullPrompt.includes('study mentor'), 'Prompt should include education persona addition');
    assert.ok(fullPrompt.includes('learning'), 'Prompt should include education-specific guidance');
    assert.ok(fullPrompt.includes(educationPersona.systemPromptAddition), 'Prompt should include the full persona addition');
  });
  
  await t.test('travel prompt includes travel addition', () => {
    const travelPersona = personaManager.getPersona('travel');
    const basePrompt = "You are an AI assistant.";
    const fullPrompt = promptTemplate.buildPrompt(basePrompt, travelPersona.systemPromptAddition);
    
    assert.ok(fullPrompt.includes('travel planner'), 'Prompt should include travel persona addition');
    assert.ok(fullPrompt.includes('exploration'), 'Prompt should include travel-specific guidance');
    assert.ok(fullPrompt.includes(travelPersona.systemPromptAddition), 'Prompt should include the full persona addition');
  });
  
  await t.test('default prompt includes default addition', () => {
    const defaultPersona = personaManager.getPersona('unknown');
    const basePrompt = "You are an AI assistant.";
    const fullPrompt = promptTemplate.buildPrompt(basePrompt, defaultPersona.systemPromptAddition);
    
    assert.ok(fullPrompt.includes('General Assistant'), 'Prompt should include default persona addition');
    assert.ok(fullPrompt.includes(defaultPersona.systemPromptAddition), 'Prompt should include the full default addition');
  });
});

test('Property 1 & 2 combined: Random space names maintain consistency and inclusion', async (t) => {
  const personaManager = new PersonaManager();
  // Mock the loadPersonas method to use our test config
  personaManager.personas = mockConfig;
  
  const promptTemplate = new PromptTemplate();
  
  // Test with various space names
  const testSpaces = ['health', 'finance', 'education', 'travel', 'HEALTH', 'Finance', 'EDUCATION', 'Travel'];
  
  for (const space of testSpaces) {
    await t.test(`space "${space}" maintains consistency and inclusion`, () => {
      // Test consistency
      const persona1 = personaManager.getPersona(space.toLowerCase());
      const persona2 = personaManager.getPersona(space.toLowerCase());
      
      assert.deepStrictEqual(persona1, persona2, `getPersona for "${space}" should be consistent`);
      
      // Test inclusion
      const basePrompt = "You are an AI assistant.";
      const fullPrompt = promptTemplate.buildPrompt(basePrompt, persona1.systemPromptAddition);
      
      assert.ok(
        fullPrompt.includes(persona1.systemPromptAddition), 
        `Prompt for "${space}" should include persona addition`
      );
    });
  }
});
