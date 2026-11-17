---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user until you both understand the plan the same way. Track the open decisions as a **design tree**, where each decision has child decisions that depend on its answer.

Ask in rounds. The **frontier** is every decision whose parent decisions are settled, so you can ask it now without guessing at an answer you haven't heard. Each round, ask every frontier question at once. Number each question and give your recommended answer. Then wait for the user's answers before the next round.

Format a round like this:

```
**Q1. <question title>.** <question body, which may run several paragraphs and list choices>

Recommended: <your answer>

---

**Q2. <question title>.** <question body>

Recommended: <your answer>
```

Word each question so that "yes" accepts your recommendation.

After each round, mark the answered decisions settled and recompute the frontier, since the answers unblock their child decisions. If a question depends on another question in the same round, ask it in a later round.

You find facts, and the user makes decisions. When a frontier question needs a fact from the environment, such as a file, a config value, or a tool's output, send a subagent with a fresh context to find it. Never ask the user for something you can look up. Keep asking while the subagent runs: only the questions that depend on its result wait for it. Put every decision to the user and wait for the answer.

The session ends when the frontier is empty: you have asked about every branch of the tree and assumed nothing silently. Do not act on the result until the user confirms that you both agree on it.
