---
name: to-spec
description: "Turn the current conversation into a spec and publish it to the project issue tracker, without interviewing the user."
disable-model-invocation: true
---

Write a spec from the current conversation and what you know of the codebase. Don't interview the user. Use what has already been discussed.

The issue tracker and triage labels should already be in your context. If they aren't, tell the user to run `/setup-matt-pocock-skills`.

## Process

1. Explore the repo to learn the current state of the code, if you haven't yet. Use the terms from the project's domain glossary throughout the spec, and follow any ADRs in the area you are changing.

2. Choose the seams where the feature will be tested. Prefer seams that already exist over new ones. Choose the highest seam that works, and put any new seam as high as possible. Fewer seams across the codebase is better, and one is ideal.

   Check with the user that these seams match what they expect.

3. Write the spec from the template below and publish it to the issue tracker. Apply the `ready-for-agent` triage label and no other triage.

<spec-template>

## Problem

The problem the user faces, from the user's point of view.

## Solution

The solution, from the user's point of view.

## User stories

A long, numbered list of user stories in this form:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see the balance of my accounts, so that I can decide how much to spend
</user-story-example>

Cover every part of the feature.

## Implementation decisions

The implementation decisions made so far. These can include:

- The modules to build or change.
- The interfaces of those modules that will change.
- Technical points the developer clarified.
- Architectural decisions.
- Schema changes.
- API contracts.
- Specific interactions.

Leave out file paths and code snippets, because they go stale quickly.

One exception: when a prototype produced a snippet that states a decision more precisely than prose can, such as a state machine, reducer, schema, or type, put it inside the decision it belongs to and note that it came from a prototype. Keep only the lines that carry the decision, not a working demo.

## Testing decisions

The testing decisions made so far, including:

- What makes a good test here. A good test checks external behavior, not implementation details.
- Which modules get tests.
- Existing tests of a similar kind in the codebase to follow.

## Out of scope

What this spec leaves out.

## Further notes

Anything else about the feature.

</spec-template>
