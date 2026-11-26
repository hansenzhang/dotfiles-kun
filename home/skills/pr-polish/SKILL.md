---
name: pr-polish
description: Cleanup checklist for a pull request's diff. Use before opening or updating a PR, when reviewing a PR diff, or when the captain asks to polish a PR or remove cruft.
---

# PR polish

Cruft is any line in the diff that a reader pays for and the system does not need: a test that proves nothing new, a comment that repeats the code, a mechanism nobody asked for. Every hunk of the diff is checked against every rule below. The rules hold for any repo; the repo's own `AGENTS.md` or `CLAUDE.md` adds to them and wins where they disagree.

## Rules

**Tests**
- Each test states one behavior a caller or user relies on, in its name.
- A test earns its place by failing for a bug no other test catches. Cut tests that cover the same branch as another test with different data, tests of the language, framework or a mock, and tests that pin private calls or internal structure.
- A bug fix keeps the test that goes red without the fix. Check it: revert the fix, run the test, see it fail.

**Comments**
- A comment says why, or names a pitfall the code cannot show. Cut comments that restate the code, narrate the change ("now uses X", "added for Y"), and commented-out code.
- When code needs a comment to explain what it does, rename or restructure it until it does not.
- Comment density matches the surrounding code.

**Simplicity**
- Each new config key, flag, abstraction, wrapper or generic mechanism has either two current callers or an explicit ask in the brief. Inline the rest.
- Dead code, unused exports, debug output and leftover scaffolding are gone.
- Names, types and idiom match the surrounding code.
- Work outside the brief goes to its own issue, or its own commit when it is a lint or test fix found along the way.

**Principles**
- Every rule in the global `AGENTS.md` applies to the diff as a checklist, above all "Prefer the simplest change that works" and the section "Code is the source of truth". Docs changed or deleted with the code they describe are part of that.
- PR bodies, commit bodies and docs follow the `unslop` skill.

## Author pass

Run this in the worker's own branch before opening or updating the PR.

1. Read `git diff <base>...HEAD` hunk by hunk against every rule. Done when every hunk is checked.
2. Fix what you found, then rerun the tests and lint.
3. Add a **Polish** section to the PR body: one line per thing removed or simplified, with the rule it broke, or "nothing found". Done when the section is in the PR body.

## Reviewer pass

Run this in a fresh context that did not write the code. It is read-only.

1. Read the brief and the PR diff (`gh pr diff <n>`), hunk by hunk against every rule. Done when every hunk is checked.
2. Post one PR comment with the findings, most cruft first. Each finding gives `file:line`, the rule, and the proposed change. Post "No polish findings" when there are none. Done when the comment is posted.
