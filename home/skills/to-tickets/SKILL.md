---
name: to-tickets
description: Break a plan, spec, or the current conversation into tracer-bullet tickets, each listing the tickets that block it, and publish them to the configured tracker (as one file per ticket for a local tracker, or with native blocking links on a real tracker).
disable-model-invocation: true
---

# To tickets

Break a plan, spec, or conversation into **tickets**. Each ticket is a tracer bullet, a thin vertical slice of the feature, and lists the tickets that **block** it.

The issue tracker and triage labels should already be in your context. If they aren't, tell the user to run `/setup-matt-pocock-skills`.

## Process

### 1. Gather context

Start from what is already in the conversation. If the user passes a reference such as a spec path, an issue number, or a URL, fetch it and read its full body and comments.

### 2. Explore the codebase (optional)

If you haven't explored the codebase yet, do so to learn the current state of the code. Use the project's glossary terms in ticket titles and descriptions, and follow the ADRs in the area you are changing.

Look for refactors that would make the feature easier to build, and do them first. Make the change easy, then make the easy change.

### 3. Draft vertical slices

Break the work into tracer-bullet tickets.

<vertical-slice-rules>

- Each slice goes through every layer (schema, API, UI, tests) for one narrow piece of behavior. Never slice by layer.
- A finished slice can be demoed or checked on its own.
- Each slice fits in one fresh context window.
- Refactors that prepare the code come first.

</vertical-slice-rules>

Give each ticket its blocking edges, which are the other tickets that must be done before it can start. A ticket with no blockers can start at once.

Wide refactors are the one exception to vertical slicing. A **wide refactor** is one mechanical change, such as renaming a column or changing the type of a shared symbol, that touches call sites across the whole codebase. A single edit breaks thousands of call sites at once, so no vertical slice can pass CI. Don't force it into a tracer bullet. Sequence it as **expand and contract** instead:

1. Expand: add the new form beside the old one, so nothing breaks.
2. Migrate: move the call sites over in batches, for example one per package or directory. Each batch is its own ticket, blocked by the expand ticket. CI stays green between batches because the old form still exists.
3. Contract: delete the old form once no caller uses it, in a ticket blocked by every migrate batch.

When even the batches can't pass CI alone, keep the same sequence but put the batches on one integration branch. Every batch then blocks a final ticket that integrates and verifies them, and only that ticket promises a green build.

### 4. Review the breakdown with the user

Show the proposed tickets as a numbered list. For each ticket, give:

- **Title**: a short descriptive name.
- **Blocked by**: the tickets that must finish first, if any.
- **Delivers**: the end-to-end behavior the ticket makes work.

Ask the user:

- Is the granularity right, or are the tickets too coarse or too fine?
- Are the blocking edges right? Each ticket should depend only on tickets that actually gate it.
- Should any tickets be merged or split?

Revise until the user approves the breakdown.

### 5. Publish the tickets

Publish the approved tickets. The tracker that `/setup-matt-pocock-skills` configured decides how blocking edges are stored. The tickets are the same either way.

- For local files, write one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` with blockers first. Each file's "Blocked by" line lists the numbers or titles it depends on. Use the local ticket template below, one ticket per file. Never put several tickets in one file.
- For a real issue tracker such as GitHub or Linear, create one issue per ticket with blockers first, so each ticket's blocking edges can point at real issue ids. Use the tracker's native blocking link where it has one. Otherwise, list the blocking issues under "Blocked by". If the source was an existing issue, make each ticket a sub-issue of it, as the tracker doc describes. Apply the `ready-for-agent` triage label unless told otherwise, because the tickets are built for an agent to pick up.

Work proceeds along the **frontier**: the tickets whose blockers are all done. In a straight chain, that means top to bottom.

Do NOT close or change any parent issue.

<local-ticket-template>

# <NN>: <Ticket title>

**What to build:** the end-to-end behavior this ticket makes work, from the user's point of view, not a list of changes per layer.

**Blocked by:** the numbers or titles of the tickets that gate this one, or "None (can start immediately)".

**Status:** ready-for-agent

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2

</local-ticket-template>

<issue-template>

## Parent

A link to the parent issue, if the source was an existing issue. Otherwise leave this section out.

## What to build

The end-to-end behavior this ticket makes work, from the user's point of view, not a list of changes per layer.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Blocked by

- A link to each blocking ticket, or "None (can start immediately)". Leave this section out when the blockers are native links.

</issue-template>

In both forms, leave out file paths and code snippets, because they go stale quickly. One exception: when a prototype produced a snippet that states a decision more precisely than prose can, such as a state machine, reducer, schema, or type, include it and note that it came from a prototype. Keep only the lines that carry the decision, not a working demo.
