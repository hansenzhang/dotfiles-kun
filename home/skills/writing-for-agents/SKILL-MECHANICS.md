# Skill mechanics

This file covers what changes when the document you are writing is a skill: frontmatter, how the skill is invoked, and router skills. Everything else about writing a skill is in [`SKILL.md`](SKILL.md).

## Invocation

There are two choices, and each trades one load for the other:

- A **model-invoked** skill has a `description`, so the agent can invoke it on its own and other skills can invoke it. You can still invoke it by typing its name, because a description adds agent invocation without removing human invocation. The description is the skill's top-level context pointer and is always loaded, so the skill pays context load permanently in exchange for being found. A model-invoked skill that contains only reference is also a good home for reference that several skills share, because each of them can invoke it, so the reference lives in one place. To set one up, leave out `disable-model-invocation` and write a description for the model that lists the trigger branches. All the pointer-writing rules in `SKILL.md` apply.
- A **user-invoked** skill hides its description from the agent. Only a human typing its name can invoke it, and no other skill can. It costs no context load, but it costs cognitive load, because you must remember that it exists. To set one up, set `disable-model-invocation: true`. The `description` is then for humans: a one-line summary without trigger lists.

Choose model invocation only when the agent, or another skill, must reach the skill on its own. If the skill only ever runs when you type its name, make it user-invoked so it costs no context load.

Reference that two user-invoked skills both need can't live in either of them, because neither has a description, so neither can invoke the other. Put it in a plain file outside the skill system, which any skill can point to.

## Splitting by invocation

`SKILL.md` covers splitting by sequence. Split off a separate model-invoked skill when it has its own leading word that should trigger it, meaning a word you actually use in your prompts, or when another skill must reach it. The new description is always loaded and costs context load, so the separate trigger has to be worth that cost.

## Router skills

When you have more user-invoked skills than you can remember, add a **router skill**: one user-invoked skill that lists the others and says when to use each. You then remember one skill instead of many. A router can only suggest the other skills, not invoke them, because user-invoked skills have no description and only a human can invoke them.
