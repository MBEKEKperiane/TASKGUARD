const OpenAI = require('openai');

// Uses Google Gemini via its OpenAI-compatible endpoint.
// Set GEMINI_API_KEY in your environment (Render → Environment tab).
const openai = new OpenAI({
  apiKey: process.env.GEMINI_API_KEY,
  baseURL: 'https://generativelanguage.googleapis.com/v1beta/openai/',
});

const SYSTEM_PROMPT = `You are TaskGuard AI, an intelligent productivity assistant.
You help users manage tasks, schedule their day efficiently, detect overload, and maintain mental wellness.
Keep responses concise, actionable, and empathetic.
When detecting burnout risk, always recommend breaks gently.`;

module.exports = { openai, SYSTEM_PROMPT };
