import { promises as fs } from 'fs';

class Persona {
  constructor(name, tone, guidelines, systemPromptAddition) {
    this.name = name;
    this.tone = tone;
    this.guidelines = guidelines;
    this.systemPromptAddition = systemPromptAddition;
  }

  buildSystemPrompt(basePrompt) {
    const guidelinesText =
      Array.isArray(this.guidelines) && this.guidelines.length > 0
        ? `\nGuidelines:\n- ${this.guidelines.join('\n- ')}`
        : '';

    return `${basePrompt}\n\nPersona: ${this.name} (tone: ${this.tone})${guidelinesText}\n\n${this.systemPromptAddition}`.trim();
  }
}

class PersonaManager {
  constructor(configPath = null) {
    // For ES modules, __dirname is not available, so we need to handle path differently
    this.configPath = configPath || new URL('../../config/personas.json', import.meta.url);
    this.personas = null;
    this.lastLoadedAt = null;
    this.lastConfigMtime = null;
  }

  async loadPersonas() {
    try {
      // If configPath is a URL object, get its pathname; otherwise use as-is
      let filePath;
      if (this.configPath instanceof URL) {
        filePath = this.configPath.pathname;
      } else {
        filePath = this.configPath.startsWith('file://')
          ? new URL(this.configPath).pathname
          : this.configPath;
      }
      
      // On Windows, URL pathname starts with a slash that needs to be removed for file paths
      const normalizedPath = process.platform === 'win32' && filePath.startsWith('/')
        ? filePath.substring(1)
        : filePath;

      const stat = await fs.stat(normalizedPath);
      const configContent = await fs.readFile(normalizedPath, 'utf8');
      const config = JSON.parse(configContent);

      this.personas = {};

      for (const [key, personaConfig] of Object.entries(config)) {
        if (!this.validatePersona(personaConfig)) {
          console.warn(`Skipping invalid persona config for key "${key}"`);
          continue;
        }

        this.personas[key.toLowerCase()] = new Persona(
          personaConfig.name,
          personaConfig.tone,
          personaConfig.guidelines,
          personaConfig.systemPromptAddition
        );
      }

      if (!this.personas.default) {
        throw new Error('Default persona is required but was not found in personas.json');
      }

      this.lastLoadedAt = new Date();
      this.lastConfigMtime = stat.mtimeMs;
      return this.personas;
    } catch (error) {
      console.error(`Error loading personas from ${this.configPath}:`, error.message);
      throw error;
    }
  }

  getPersona(spaceName) {
    if (!this.personas) {
      throw new Error('Personas not loaded. Call loadPersonas() first.');
    }
    
    // Normalize spaceName to lowercase for case-insensitive matching
    const normalizedSpaceName = spaceName.toLowerCase();
    
    // Return the specific persona if it exists, otherwise return the default
    return this.personas[normalizedSpaceName] || this.personas.default;
  }

  validatePersona(persona) {
    if (!persona) {
      return false;
    }
    
    // Check if persona has all required properties
    const hasRequiredProps = persona.hasOwnProperty('name') &&
                           persona.hasOwnProperty('tone') &&
                           persona.hasOwnProperty('guidelines') &&
                           persona.hasOwnProperty('systemPromptAddition');
    
    if (!hasRequiredProps) {
      return false;
    }
    
    // Check if properties have valid values
    if (typeof persona.name !== 'string' || persona.name.trim() === '') {
      return false;
    }
    
    if (typeof persona.tone !== 'string' || persona.tone.trim() === '') {
      return false;
    }
    
    if (!Array.isArray(persona.guidelines) || persona.guidelines.length === 0) {
      return false;
    }
    
    if (typeof persona.systemPromptAddition !== 'string' || persona.systemPromptAddition.trim() === '') {
      return false;
    }
    
    // Validate that all guidelines are strings
    for (const guideline of persona.guidelines) {
      if (typeof guideline !== 'string' || guideline.trim() === '') {
        return false;
      }
    }
    
    return true;
  }

  /**
   * Reload personas if the config file has changed on disk.
   */
  async ensureLatestPersonas() {
    try {
      if (!this.personas) {
        await this.loadPersonas();
        return;
      }

      let filePath;
      if (this.configPath instanceof URL) {
        filePath = this.configPath.pathname;
      } else {
        filePath = this.configPath.startsWith('file://')
          ? new URL(this.configPath).pathname
          : this.configPath;
      }

      const normalizedPath = process.platform === 'win32' && filePath.startsWith('/')
        ? filePath.substring(1)
        : filePath;

      const stat = await fs.stat(normalizedPath);
      if (!this.lastConfigMtime || stat.mtimeMs > this.lastConfigMtime) {
        console.info('Persona configuration changed on disk. Reloading personas...');
        await this.loadPersonas();
      }
    } catch (error) {
      console.error('Failed to refresh personas, continuing with cached copy:', error.message);
    }
  }
}

export { PersonaManager, Persona };
