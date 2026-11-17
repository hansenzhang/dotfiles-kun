---
name: prototype
description: Build a throwaway prototype to answer a design question. Use when the user wants to sanity-check whether a state model or logic feels right, or explore what a UI should look like.
---

# Prototype

A prototype is throwaway code that answers one question. The question decides what you build.

## Pick a branch

Work out which question the prototype answers from the user's prompt or the surrounding code. If the user is around, ask.

- "Is this logic or state model right?" Follow [LOGIC.md](LOGIC.md). Build one HTML file that someone who doesn't write code can open and use. It has buttons for free play and tabs with guided walkthroughs, and it runs the state machine through cases that are hard to work out on paper.
- "What should this look like?" Follow [UI.md](UI.md). Build several very different versions of the UI on one route. A URL search parameter and a bar fixed to the bottom of the page switch between them.

The two branches produce very different things, so picking the wrong one wastes the whole prototype. If the question could go either way and the user isn't available, pick the branch that fits the surrounding code: logic for a backend module, UI for a page or component. State that assumption at the top of the prototype.

## Rules for both branches

1. Mark it as throwaway from the start. Put the prototype next to the module or page it is for, so its context is obvious, but name it so a reader can see it is a prototype and not production code. For throwaway UI routes, follow the project's existing routing convention instead of adding a new top-level structure.
2. Make it start with one command. A UI prototype starts from one command in the project's task runner, such as `pnpm <name>`, `python <path>`, or `bun <path>`. A logic prototype is one HTML file the user double-clicks.
3. Keep state in memory. If the prototype depended on a database, it couldn't check how data should be stored. If the question is about the database, use a scratch database or a local file with a name like "PROTOTYPE, wipe me".
4. Skip the polish. Write no tests, no abstractions, and no error handling beyond what the prototype needs to run. The goal is to learn something quickly.
5. Show the state. After every action in a logic prototype, and on every version switch in a UI prototype, print or render all the relevant state so the user can see what changed.
6. Record the result when done. Move any decision the prototype confirmed into the real code. Commit the prototype to a throwaway branch, not main, and link that branch from the implementation issue so later readers can find it. Also record the answer, meaning the question it settled and the verdict, in the issue or a commit message. Main keeps only the confirmed decision.
