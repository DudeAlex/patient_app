import 'dotenv/config';
import { TogetherClient } from '../src/llm/together_client.js';
import { resolveChatModel } from '../src/llm/models.js';

const modelArg = process.argv[2];
const model = resolveChatModel(modelArg);

async function main() {
  const client = new TogetherClient({ model });
  const res = await client.sendChat({
    messages: [
      { role: 'system', content: 'You are a concise assistant.' },
      { role: 'user', content: 'Say hello in one short sentence.' },
    ],
    maxTokens: 64,
  });
  console.log(JSON.stringify(res, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
