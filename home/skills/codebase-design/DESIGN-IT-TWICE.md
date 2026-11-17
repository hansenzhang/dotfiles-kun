# Design it twice

When the user wants to explore alternative interfaces for a module they chose to deepen, use parallel subagents as described below. The idea comes from Ousterhout's "Design It Twice": your first design is unlikely to be the best one.

This file uses the terms module, interface, seam, adapter, and leverage from [SKILL.md](SKILL.md).

## Process

### 1. Describe the problem

Before you start any subagent, write the user an explanation of the problem for the chosen module:

- The constraints any new interface must meet.
- The dependencies it would use, and the category of each (see [DEEPENING.md](DEEPENING.md)).
- A rough code sketch that makes the constraints concrete. It illustrates the constraints and is not a proposal.

Show this to the user, then go straight to step 2. The user reads it while the subagents work.

### 2. Start the subagents

Start three or more subagents in parallel, each with a fresh context. Each one must produce a very different interface for the deepened module.

Give each subagent its own technical brief: file paths, how the code is coupled, the dependency category from [DEEPENING.md](DEEPENING.md), and what sits behind the seam. This brief is separate from the user-facing explanation in step 1. Give each subagent a different design constraint:

- Subagent 1: "Minimize the interface: at most one to three entry points. Get as much behavior as possible out of each entry point."
- Subagent 2: "Maximize flexibility: support many use cases and extensions."
- Subagent 3: "Optimize for the most common caller: make the default case trivial."
- Subagent 4, if it applies: "Design around ports and adapters for dependencies across the seam."

Put the terms from [SKILL.md](SKILL.md) and from `docs/glossary.md` in each brief, so every subagent uses the same architecture terms and the project's domain terms.

Each subagent returns:

1. The interface: types, methods, and parameters, plus invariants, ordering, and error modes.
2. An example of a caller using it.
3. What the implementation hides behind the seam.
4. The dependency strategy and adapters (see [DEEPENING.md](DEEPENING.md)).
5. Trade-offs: where it gives callers the most leverage, and where it gives the least.

### 3. Present and compare

Present the designs one at a time so the user can take each in, then compare them in prose. Compare them on depth, on locality (where changes land), and on seam placement.

Then recommend one. Say which design you think is strongest and why. If parts of different designs would combine well, propose the combination. Give a clear recommendation rather than a list of options.
