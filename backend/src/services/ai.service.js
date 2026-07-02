const { openai, SYSTEM_PROMPT } = require('../config/openai');

// Score task priority using AI (0–100)
const scorePriority = async ({ title, description, dueDate, priority, estimatedDuration }) => {
  const hoursUntilDue = dueDate
    ? (new Date(dueDate) - Date.now()) / 36e5
    : null;

  const prompt = `Score the priority of this task from 0 to 100 (higher = more urgent/important).
Task: "${title}"
Description: "${description || 'none'}"
User priority: ${priority || 'MEDIUM'}
Hours until due: ${hoursUntilDue ? hoursUntilDue.toFixed(1) : 'no deadline'}
Estimated duration: ${estimatedDuration || 'unknown'} minutes
Reply with ONLY a number between 0 and 100.`;

  const res = await openai.chat.completions.create({
    model: 'gemini-2.0-flash',
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 5,
    temperature: 0,
  });

  const score = parseFloat(res.choices[0].message.content.trim());
  return isNaN(score) ? 50 : Math.min(100, Math.max(0, score));
};

// Parse natural language into structured task data
const parseNaturalLanguageTask = async (text) => {
  const now = new Date().toISOString();
  const prompt = `Parse this natural language task request into JSON.
Current datetime: ${now}

Request: "${text}"

Return ONLY valid JSON with these fields (use null if not mentioned):
{
  "title": "string",
  "description": "string | null",
  "dueDate": "ISO 8601 datetime | null",
  "startTime": "ISO 8601 datetime | null",
  "remindAt": "ISO 8601 datetime | null",
  "estimatedDuration": "number in minutes | null",
  "priority": "LOW | MEDIUM | HIGH | URGENT",
  "recurrenceType": "NONE | DAILY | WEEKLY | MONTHLY"
}`;

  const res = await openai.chat.completions.create({
    model: 'gemini-2.0-flash',
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 300,
    temperature: 0,
    response_format: { type: 'json_object' },
  });

  return JSON.parse(res.choices[0].message.content);
};

// Generate AI chat response
const chat = async (userId, userMessage, history = []) => {
  const messages = [
    { role: 'system', content: SYSTEM_PROMPT },
    ...history.slice(-10).map((m) => ({ role: m.role, content: m.content })),
    { role: 'user', content: userMessage },
  ];

  const res = await openai.chat.completions.create({
    model: 'gemini-2.0-flash',
    messages,
    max_tokens: 500,
    temperature: 0.7,
  });

  return res.choices[0].message.content;
};

// Generate AI daily plan from today's tasks
const generateDailyPlan = async (tasks) => {
  if (!tasks.length) {
    return { plan: "You have no tasks scheduled for today. Great time for proactive work!", suggestions: [] };
  }

  const taskList = tasks.map((t, i) =>
    `${i + 1}. "${t.title}" | Priority: ${t.priority} | Est: ${t.estimatedDuration || '?'} min | Due: ${t.dueDate ? new Date(t.dueDate).toLocaleTimeString() : 'no time'}`
  ).join('\n');

  const prompt = `You are a productivity coach. Create an optimized daily schedule.

Tasks for today:
${taskList}

Return JSON with:
{
  "plan": "brief overview paragraph",
  "schedule": [{ "taskTitle": "", "suggestedTime": "HH:MM", "reason": "" }],
  "suggestions": ["tip1", "tip2"],
  "totalEstimatedHours": number
}`;

  const res = await openai.chat.completions.create({
    model: 'gemini-2.0-flash',
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 600,
    temperature: 0.5,
    response_format: { type: 'json_object' },
  });

  return JSON.parse(res.choices[0].message.content);
};

// Suggest best time for a single task
const suggestBestTime = async (task, existingTasks) => {
  const occupied = existingTasks
    .filter((t) => t.startTime)
    .map((t) => `${new Date(t.startTime).toLocaleTimeString()} - ${t.title}`)
    .join('\n');

  const prompt = `Suggest the best time slot today for this task.
Task: "${task.title}"
Estimated duration: ${task.estimatedDuration || 30} minutes
Priority: ${task.priority}

Already scheduled today:
${occupied || 'Nothing scheduled yet.'}

Reply with JSON: { "suggestedTime": "HH:MM", "reason": "brief reason" }`;

  const res = await openai.chat.completions.create({
    model: 'gemini-2.0-flash',
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 150,
    temperature: 0.4,
    response_format: { type: 'json_object' },
  });

  return JSON.parse(res.choices[0].message.content);
};

// Re-prioritize all tasks
const reprioritizeTasks = async (tasks) => {
  if (!tasks.length) return [];

  const taskList = tasks.map((t) => ({
    id: t.id,
    title: t.title,
    dueDate: t.dueDate,
    priority: t.priority,
    estimatedDuration: t.estimatedDuration,
  }));

  const prompt = `Re-prioritize these tasks. Assign each an aiPriorityScore (0-100).
Higher score = more urgent/important.

Tasks: ${JSON.stringify(taskList)}

Return JSON array: [{ "id": "", "aiPriorityScore": number, "reasoning": "" }]`;

  const res = await openai.chat.completions.create({
    model: 'gemini-2.0-flash',
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 800,
    temperature: 0.2,
    response_format: { type: 'json_object' },
  });

  const parsed = JSON.parse(res.choices[0].message.content);
  return Array.isArray(parsed) ? parsed : parsed.tasks || [];
};

// Check for overload / burnout risk
const checkOverload = async (tasks, focusMinutesToday) => {
  const totalEstimated = tasks.reduce((s, t) => s + (t.estimatedDuration || 30), 0);
  const highPriorityCount = tasks.filter((t) => ['HIGH', 'URGENT'].includes(t.priority)).length;
  const overdueCount = tasks.filter((t) => t.status === 'OVERDUE').length;

  const riskScore = Math.min(100,
    (totalEstimated / 480) * 40 +   // 8h workday = 40 pts
    (highPriorityCount / tasks.length || 0) * 30 +
    (overdueCount * 10) +
    (focusMinutesToday > 300 ? 20 : 0)  // >5h focus = 20 pts
  );

  let level = 'LOW';
  let message = "Your workload looks manageable today.";
  let suggestions = [];

  if (riskScore >= 70) {
    level = 'HIGH';
    message = "Please take a break, your mental health is at stake. You've been working hard; it's time to recharge your energy.";
    suggestions = [
      "Take a 15-minute break now.",
      "Reschedule 2-3 non-urgent tasks to tomorrow.",
      "Avoid adding new tasks today.",
    ];
  } else if (riskScore >= 40) {
    level = 'MEDIUM';
    message = "Your schedule is getting busy. Consider taking short breaks.";
    suggestions = [
      "Use the Pomodoro technique (25 min work, 5 min break).",
      "Prioritize your top 3 tasks and defer the rest.",
    ];
  }

  return {
    riskScore: Math.round(riskScore),
    level,
    message,
    suggestions,
    stats: {
      totalEstimatedMinutes: totalEstimated,
      highPriorityTasks: highPriorityCount,
      overdueTasks: overdueCount,
      focusMinutesToday,
    },
  };
};

// Generate productivity insights
const generateInsights = async (weeklyData) => {
  const prompt = `Analyze this weekly productivity data and provide insights.
Data: ${JSON.stringify(weeklyData)}

Return JSON:
{
  "summary": "paragraph",
  "strengths": ["strength1", "strength2"],
  "improvements": ["area1", "area2"],
  "focusTip": "one actionable tip for next week"
}`;

  const res = await openai.chat.completions.create({
    model: 'gemini-2.0-flash',
    messages: [{ role: 'user', content: prompt }],
    max_tokens: 400,
    temperature: 0.6,
    response_format: { type: 'json_object' },
  });

  return JSON.parse(res.choices[0].message.content);
};

module.exports = {
  scorePriority,
  parseNaturalLanguageTask,
  chat,
  generateDailyPlan,
  suggestBestTime,
  reprioritizeTasks,
  checkOverload,
  generateInsights,
};
