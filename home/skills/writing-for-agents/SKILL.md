---
name: writing-for-agents
description: Writing documents for agents. Use when creating or editing skills, or modifying AGENTS.md or CLAUDE.md.
---

This is a reference for writing any document an agent reads: a skill, an `AGENTS.md` or `CLAUDE.md`, or a doc that another document points to. The packaging differs, but the writing rules are the same. The rules below make an agent follow the same process on every run, even though the output differs between runs.

If the document is a skill, also read [`SKILL-MECHANICS.md`](SKILL-MECHANICS.md) for frontmatter, choosing how the skill is invoked, and router skills.

## Context pointers

A **context pointer** is a reference in the agent's context that names material outside the context and states when to load it. A skill's description is a context pointer, and so is a line in `AGENTS.md` that names a doc. The pointer's wording, not the material it points to, decides when the agent loads that material and how reliably. If the agent must have some material but the pointer to it is weakly worded, the agent will load it only some of the time. Fix the wording first, and copy the material inline only if better wording doesn't work.

A pointer does two things. It says what the material is, and it lists the **branches** that should make the agent load it. A branch is a distinct case the document handles, so different runs take different paths through the document. A pointer that is always loaded costs tokens on every turn, so prune it even harder than the body:

- Put the leading word (see [Leading words](#leading-words)) at the start of the pointer, because the pointer is what makes the agent load the material.
- Write one trigger per branch. Synonyms that name the same branch are that branch written twice. Merge them, and keep only branches that really differ.
- Cut any description of the material that the body already gives.

## Context load and cognitive load

Every document and pointer you add costs one of two things:

- **Context load** is the cost of always-loaded material on the agent's context window. An `AGENTS.md` line, a skill description, and anything else in context on every turn uses tokens and attention whether or not it is relevant.
- **Cognitive load** is the cost on the human, who has to remember which documents exist and when to use each one. The human acts as the index. Don't simply minimize this cost, because it is what keeps the human in control. Spend it where human judgment matters, and remove it where it doesn't.

Material that only a pointer reaches costs context load for the pointer's line alone. Material with no pointer costs only cognitive load, because the human must remember it exists.

## Information hierarchy

A document contains two kinds of content. **Steps** are the ordered actions the agent performs. **Reference** is definitions, rules, and facts that the agent looks up when needed. A document can be all steps, like a recipe, all reference, like a review's rules or this skill, or a mix. The main decision is where each piece sits in the **information hierarchy**, which ranks material by how soon the agent needs it:

1. **Steps in the file** come first. They are what the agent does, in order.
2. **Reference in the file** is looked up when needed. It is often a flat list of equal items, such as every rule of a review at the same level. That is a fine arrangement.
3. **Reference outside the file** sits in a separate file that a context pointer reaches, and loads only when the pointer triggers. It can be a sibling file in the same folder or an external doc that any document can point to.

If you move too little out of the main file, the top of the document grows too long. If you move too much, you hide material the agent actually needs. Balancing those two is the whole decision.

**Progressive disclosure** means moving material down the hierarchy, out of the main file and behind a pointer, so the top stays readable. Its main purpose is to protect the hierarchy, not to save tokens. Branches give the clearest test: keep in the file what every branch needs, and move behind a pointer what only some branches need. When a document has steps, reference that should have been moved out buries the steps, so the agent attends to them only some of the time. That makes runs less consistent as well as harder to read.

**Co-location** decides what sits next to each piece once the hierarchy has placed it. Keep a concept's definition, rules, and caveats under one heading instead of spreading them out, so reading one part brings the rest with it. Test it this way: the document should read like documentation written for the agent. Grouped material does, and scattered material doesn't. Scattering is different from duplication. Duplication repeats one meaning in two places, and scattering splits one meaning across many.

**Sprawl** is a document that is too long, even when every line is current and says something new. The agent's attention spreads thin across the extra lines, and each line is one more to keep current. Fix it with the hierarchy: move reference behind pointers, and split by branch or by sequence so each path carries only what it needs.

## Steps and completion criteria

Every step ends with a **completion criterion**, the condition that tells the agent the step is done. Two properties of a criterion change how the agent behaves:

- **Clarity** is whether the agent can tell done from not done. A vague criterion such as "understanding reached" invites **premature completion**: the agent ends the step before it is really done, because its attention moves to finishing. The steps still visible after this one pull it forward, and a clear criterion holds it back. Fix this in order. First, make the criterion sharper, which is local and cheap. Only if the criterion can't be made sharp, and you have actually seen the agent rush, hide the later steps by splitting the sequence. Hiding works only across a real context boundary, such as a handoff or a subagent. An inline skill call leaves the later steps in context, so it hides nothing.
- **Demand** is how much the criterion requires. "Every modified model accounted for" forces thorough work, and "produce a change list" doesn't. Demand decides how much digging the agent does within a step, even though the digging isn't written as a step of its own. Demand applies to reference as well as steps. "Every rule applied" binds a flat list of rules the same way "every step done" binds a sequence, which is how a document of pure reference can still require exhaustive work.

The strongest criteria can be checked and require exhaustive work.

## When to split a document

Splitting one document into two costs one of the two loads, so split only when the split pays for itself:

- Split by sequence when the later steps tempt the agent to rush the current one. With the later steps out of view, the agent does more digging on the current step. The reverse also holds: merging two sequences shows each step the steps that follow, which invites premature completion.
- Split by invocation. This applies only to skills. See [`SKILL-MECHANICS.md`](SKILL-MECHANICS.md).

## Leading words

A **leading word** is a short concept the model already knows from pretraining, which the agent thinks with while it follows the document. Examples are _lesson_, _frontier_, and _tracer bullets_. Repeat the word itself, not a sentence explaining it. Each use adds to its definition, and it steers a whole area of behavior with very few tokens, because it uses what the model already knows. You can coin your own word if you define it clearly, but a made-up word carries no prior meaning, so you pay in definition tokens for what an existing word gives for free. Try an existing word first.

A leading word works in two places. In the body, it steers execution: the agent behaves the same way each time the word appears, and inside a flat list of reference, it tells the agent what kind of thing to look for. In a pointer, it steers loading: when the same word appears in your prompts, your docs, and your code, the agent connects that shared word to the material and loads it more reliably.

Look for places to replace text with a leading word, such as three adjectives repeated in three places, or a pointer that uses a whole sentence to hint at one idea. Each one can shrink to a single word:

- "fast, deterministic, low-overhead" becomes _tight_, as in a _tight_ loop.
- "a loop you believe in" becomes _red_, which turns a vague gate into a state you can observe: the loop goes _red_ on the bug, or it doesn't.

This saves tokens and gives the agent a clearer concept to think with. Assume every document repeats things that leading words could replace, and look for them.

Prohibitions have the opposite effect of leading words. Telling the agent not to do something puts that behavior into context and makes it more likely, not less. If you say "don't think of an elephant", the reader thinks of an elephant. The negation is a weak modifier on a strong concept, so the agent half-reads the ban as an instruction. State the behavior you want instead, such as "write one-line comments", so the unwanted behavior is never mentioned. Use a prohibition only as a hard guardrail you can't state positively, and even then, pair it with the positive behavior so the agent's attention lands on what to do.

## Pruning

- Keep each meaning in one place, so changing a behavior means editing one place. Duplication, the same meaning in two or more places, costs maintenance and tokens, and makes that meaning look more important than it is. A leading word is the deliberate opposite: it repeats a word, never a meaning.
- The environment is also a source of truth: `package.json` scripts, config files, the directory layout, and `--help` output. A document that repeats the environment is a **cache**, a copy of a lookup, and it is worth its cost only when the lookup is expensive. Write down what the agent can't find by looking, such as an unwritten convention, the reason behind a choice, or a pitfall that no config file reveals. Leave lookups that take one file or one command to the environment, where they can't go stale.
- Check every line for relevance: does it still affect what the document does? A line is irrelevant if it never affected the task, for example pure explanation, or a branch that should be moved behind a pointer. It also becomes irrelevant when the behavior it describes changes. Shorter documents are easier to keep relevant. Without regular pruning, stale lines pile up, because adding a line feels safe and removing one feels risky, until finding the current lines takes real digging.
- Check each sentence for **no-ops**. A no-op is an instruction the model already follows by default, so it costs tokens and changes nothing. Test it by asking whether it changes the agent's behavior compared to the default. The answer depends on the model, not on the reader. If two people disagree about whether a sentence is a no-op, they disagree about the default, and running the document settles it. When a sentence fails the test, delete the whole sentence instead of trimming words. The same test applies to leading words. A word too weak to change the default, such as _be thorough_ when the agent is already fairly thorough, is a no-op. Fix it with a stronger word, such as _relentless_, not with a different technique.
