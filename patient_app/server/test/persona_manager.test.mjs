import test from 'node:test';
import assert from 'node:assert';
import { fileURLToPath } from 'url';
import { join } from 'path';
import { PersonaManager } from '../src/llm/persona_manager.js';

// Use the actual config file that was created - resolve relative to this test file
const __filename = fileURLToPath(import.meta.url);
const __dirname = join(__filename, '..');
const configPath = join(__dirname, '..', 'config', 'personas.json');

test('PersonaManager - loading personas from file', async (t) => {
  const personaManager = new PersonaManager(configPath);
  
  await t.test('should load personas from config file', async () => {
    const personas = await personaManager.loadPersonas();
    
    assert.ok(personas);
    assert.ok(personas.health);
    assert.ok(personas.finance);
    assert.ok(personas.default);
    assert.strictEqual(personas.health.name, 'Health Companion');
    assert.strictEqual(personas.finance.tone, 'practical, budget-conscious, clear');
    assert.strictEqual(personas.default.systemPromptAddition, 'You are a general assistant. Be helpful, concise, and friendly in your responses. Provide general guidance and assistance with various topics.');
  });
});

test('PersonaManager - getting persona for each Space', async (t) => {
  const personaManager = new PersonaManager(configPath);
  await personaManager.loadPersonas();
  
  await t.test('should get health persona for health space', () => {
    const persona = personaManager.getPersona('health');
    assert.strictEqual(persona.name, 'Health Companion');
    assert.strictEqual(persona.tone, 'empathetic, cautious, supportive');
  });
  
  await t.test('should get finance persona for finance space', () => {
    const persona = personaManager.getPersona('finance');
    assert.strictEqual(persona.name, 'Finance Advisor');
    assert.strictEqual(persona.systemPromptAddition, 'You are a finance advisor. Focus on practical money management, budgeting, and saving. Provide clear, actionable financial tips while encouraging responsible spending and saving habits.');
  });
  
  await t.test('should get default persona for unknown space', () => {
    const persona = personaManager.getPersona('unknown');
    assert.strictEqual(persona.name, 'General Assistant');
  });
  
  await t.test('should handle case-insensitive space names', () => {
    const persona = personaManager.getPersona('HEALTH');
    assert.strictEqual(persona.name, 'Health Companion');
  });
});

test('PersonaManager - default persona fallback', async (t) => {
  const personaManager = new PersonaManager(configPath);
  await personaManager.loadPersonas();
  
  await t.test('should return default persona when space does not exist', () => {
    const persona = personaManager.getPersona('nonexistent');
    assert.strictEqual(persona.name, 'General Assistant');
  });
});

test('PersonaManager - validation', async (t) => {
  const personaManager = new PersonaManager(configPath);
  await personaManager.loadPersonas();
  
  await t.test('should validate valid persona', () => {
    const validPersona = {
      name: 'Test Persona',
      tone: 'friendly',
      guidelines: ['Be helpful'],
      systemPromptAddition: 'This is a test persona'
    };
    
    const isValid = personaManager.validatePersona(validPersona);
    assert.strictEqual(isValid, true);
  });
  
  await t.test('should invalidate persona with missing properties', () => {
    const invalidPersona = {
      name: 'Test Persona',
      // Missing other required properties
    };
    
    const isValid = personaManager.validatePersona(invalidPersona);
    assert.strictEqual(isValid, false);
  });
  
  await t.test('should invalidate persona with empty name', () => {
    const invalidPersona = {
      name: '',
      tone: 'friendly',
      guidelines: ['Be helpful'],
      systemPromptAddition: 'This is a test persona'
    };
    
    const isValid = personaManager.validatePersona(invalidPersona);
    assert.strictEqual(isValid, false);
  });
  
  await t.test('should invalidate persona with non-array guidelines', () => {
    const invalidPersona = {
      name: 'Test Persona',
      tone: 'friendly',
      guidelines: 'Not an array',
      systemPromptAddition: 'This is a test persona'
    };
    
    const isValid = personaManager.validatePersona(invalidPersona);
    assert.strictEqual(isValid, false);
  });
  
  await t.test('should invalidate persona with empty guidelines array', () => {
    const invalidPersona = {
      name: 'Test Persona',
      tone: 'friendly',
      guidelines: [],
      systemPromptAddition: 'This is a test persona'
    };
    
    const isValid = personaManager.validatePersona(invalidPersona);
    assert.strictEqual(isValid, false);
  });
  
  await t.test('should invalidate persona with empty systemPromptAddition', () => {
    const invalidPersona = {
      name: 'Test Persona',
      tone: 'friendly',
      guidelines: ['Be helpful'],
      systemPromptAddition: ''
    };
    
    const isValid = personaManager.validatePersona(invalidPersona);
    assert.strictEqual(isValid, false);
  });
});
