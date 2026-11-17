---
name: diagnosing-bugs
description: Diagnosis loop for hard bugs and performance regressions. Use when the user says "diagnose"/"debug this", or reports something broken/throwing/failing/slow.
---

# Diagnosing bugs

A process for hard bugs. Skip a phase only when you can say why it doesn't apply.

When you explore the codebase, read `docs/glossary.md` if it exists, to learn what the relevant modules are, and check the ADRs in the area you are working in.

## Redact

This skill has you show commands, output, and captured files. Replace every secret with `<REDACTED>` before you show anything. Read credentials from environment variables in your loops, so they stay out of what you show. Captured files often contain auth headers, so quote only the lines that show the problem.

If the redacted output isn't enough to diagnose the bug, say so and ask the user.

## Phase 1: Build a feedback loop

This phase matters most. If you have a fast, reliable pass/fail check that fails on this specific bug, you will find the cause, because bisection, hypothesis testing, and instrumentation all depend on that check. Without one, reading code won't find the cause.

Spend most of your effort here. Try many approaches, and keep going until one works.

### Ways to build a loop, roughly in this order

1. A failing test at whichever level reaches the bug: unit, integration, or end-to-end.
2. A curl or HTTP script against a running dev server.
3. A CLI call with a fixture input, diffing stdout against a known-good snapshot.
4. A headless browser script (Playwright or Puppeteer) that drives the UI and asserts on the DOM, console, or network.
5. A replay of a captured trace. Save a real request, payload, or event log to disk, and replay it through the code path on its own.
6. A throwaway test rig. Start the smallest part of the system that reaches the bug, such as one service with mocked dependencies, and trigger the bug's code path with one function call.
7. A property or fuzz loop. If the bug is "sometimes the output is wrong", run 1000 random inputs and look for the failure.
8. A bisection script. If the bug appeared between two known states, such as commits, datasets, or versions, automate "start at state X, check, repeat" so `git bisect run` can drive it.
9. A differential loop. Run the same input through the old and new versions, or through two configs, and diff the outputs.
10. A human-in-the-loop script, as a last resort. If a person must click something, guide them with `scripts/hitl-loop.template.sh` so the loop still has fixed steps, and their answers come back to you.

Once you have the right loop, most of the work is done.

### Improve the loop

Once you have a loop, improve it:

- Make it faster. Cache setup, skip unrelated initialization, and run fewer tests.
- Make the signal more specific. Assert on the exact symptom, not "didn't crash".
- Make it deterministic. Pin the time, seed the random number generator, isolate the file system, and block the network.

A flaky 30-second loop is barely better than none. A deterministic 2-second loop lets you test a hypothesis in seconds.

### Bugs that don't reproduce every time

Aim for a higher reproduction rate rather than a clean repro. Run the trigger 100 times, run it in parallel, add load, narrow the timing window, or insert sleeps. A bug that fails 50% of the time can be debugged, and one that fails 1% of the time can't, so keep raising the rate.

### When you can't build a loop

Stop and say so. List what you tried. Ask the user for one of:

- Access to an environment where the bug reproduces.
- A redacted capture, such as a HAR file, a log dump, a core dump, or a screen recording with timestamps.
- Permission to add temporary instrumentation in production.

Don't start forming hypotheses without a loop.

### Done when a fast loop fails on the bug

Phase 1 is done when you can name one command, such as a script path, a test command, or a curl call, that you have already run at least once. Show the command and its redacted output. The command must be:

- [ ] Able to fail on this bug. It runs the bug's actual code path and asserts the user's exact symptom, so it fails on this bug and passes once the bug is fixed. "Runs without errors" is not enough.
- [ ] Deterministic. It gives the same result every run. For a flaky bug, it reproduces at a fixed, high rate, as described above.
- [ ] Fast. It takes seconds, not minutes.
- [ ] Runnable by you alone. A human takes part only through `scripts/hitl-loop.template.sh`.

If you notice yourself reading code to form a theory before this command exists, stop. Jumping to a hypothesis early is the mistake this skill exists to prevent. Without the command, don't start phase 2.

## Phase 2: Reproduce and minimize

Run the loop and watch it fail when the bug appears.

Confirm that:

- [ ] The loop shows the failure the user described, not a different failure nearby. A different bug leads to the wrong fix.
- [ ] The failure happens on every run, or, for a flaky bug, often enough to debug.
- [ ] You have recorded the exact symptom, such as the error message, wrong output, or timing, so later phases can check that the fix addresses it.

### Minimize

Once the loop fails, shrink the repro to the smallest scenario that still fails. Remove inputs, callers, config, data, and steps one at a time, and rerun the loop after each removal. Keep only what the failure needs.

A minimal repro leaves fewer parts to suspect in phase 3, and it becomes the regression test in phase 5.

This step is done when removing any remaining element makes the loop pass.

Don't go on until you have both reproduced and minimized the bug.

## Phase 3: Form hypotheses

Write three to five hypotheses, ranked by likelihood, before you test any of them. With only one hypothesis, you tend to fixate on the first plausible idea.

Each hypothesis must be falsifiable, so state the prediction it makes:

> "If <X> is the cause, then <changing Y> will make the bug disappear, or <changing Z> will make it worse."

If you can't state a prediction, the hypothesis is only a hunch. Drop it or make it specific.

Show the ranked list to the user before testing. The user often knows something that changes the ranking ("we just deployed a change to #3"), or has already ruled some out. This check costs little and can save a lot of time. Don't wait for an answer if the user is away. Continue with your own ranking.

## Phase 4: Instrument

Each probe tests one prediction from phase 3. Change one variable at a time.

Prefer, in this order:

1. A debugger or REPL, if the environment has one. One breakpoint tells you more than ten log lines.
2. Targeted logs at the places that tell the hypotheses apart.
3. Never log everything and search the output.

Give every debug log a unique prefix, such as `[DEBUG-a4f2]`, so one search finds them all at cleanup. Logs without the prefix get left behind.

For performance regressions, logs are usually the wrong tool. Take a baseline measurement first with a timing script, `performance.now()`, a profiler, or a query plan, then bisect. Measure before you fix.

## Phase 5: Fix and add a regression test

Write the regression test before the fix, but only if a correct seam exists for it.

A correct seam is one where the test reproduces the bug the way it happens at the real call site. If the only available seam is too shallow, the test gives false confidence. Examples are a test with a single caller when the bug needs several, or a unit test that can't reproduce the chain of calls that triggers the bug.

If no correct seam exists, report that as a finding. The code's structure prevents a test from guarding against this bug. Raise it for the next phase.

If a correct seam exists:

1. Turn the minimized repro into a failing test at that seam.
2. Watch it fail. If you made it fail by changing code or a fixture, `diff` against an unchanged copy to prove your change took effect before you trust the result.
3. Apply the fix.
4. Watch the test pass.
5. Rerun the phase 1 loop against the original scenario, before minimization.

## Phase 6: Clean up

Before you call the bug fixed, check that:

- [ ] The original repro no longer fails. Rerun the phase 1 loop.
- [ ] The regression test passes, or you have written down why no correct seam exists.
- [ ] Every `[DEBUG-...]` log is gone. Search for the prefix.
- [ ] Throwaway prototypes are deleted, or moved to a clearly marked debug location.
- [ ] The commit or PR message states the hypothesis that turned out correct, so the next person debugging learns from it.
