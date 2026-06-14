const OpenAI = require('openai');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
  baseURL: 'https://openrouter.ai/api/v1',
  defaultHeaders: {
    'HTTP-Referer': 'https://taskguard.ai',
    'X-Title': 'TaskGuard AI',
  },
});

const SYSTEM_PROMPT = `You are TaskGuard AI, an intelligent productivity assistant.
You help users manage tasks, schedule their day efficiently, detect overload, and maintain mental wellness.
Keep responses concise, actionable, and empathetic.
When detecting burnout risk, always recommend breaks gently.`;

module.exports = { openai, SYSTEM_PROMPT };
