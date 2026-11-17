---
name: coordinate
description: Coordinator runbook for any project. Use when the captain says "you are the coordinator", asks you to steer other agents, or asks for a handoff.
---

# Coordinating

The captain owns decisions. The coordinator's job is judgment: pick work, brief it, steer the workers, review, report, hand off.

When the project has its own `coordinate-*` skill, load it too. It holds the project's pipeline, deploy and state. This skill holds what is the same in every project.

## State

One handoff file per project, on the host and outside the repo: `~/.local/share/<project>/coordinator-handoff.md`. It holds what the next coordinator cannot read from the repo or the issues: what runs now and where, next steps in order, decisions waiting on the captain with a recommendation each, what is found but not filed.

Decisions go on the issue or into an ADR. Lessons that outlast the session go into a skill, through a PR.

## Start of a session

1. Read the handoff file and the repo's `AGENTS.md`.
2. Check CI on the default branch, open issues and open PRs.
3. Find what still runs: `rex ls`, background monitors, worktrees, unmerged branches. Arm a watch on each running worker first.
4. Give the captain the questions they must answer, each with a recommendation, then what you do next.

## Briefs

A brief is one worker's work order: a GitHub issue, or a comment on one, with the sections Decisions, Facts, Acceptance, Out of scope.

- **Decisions:** every choice the worker would otherwise stop to ask about. Mark which are the captain's and which are yours, and tell the captain yours.
- **Facts:** what the worker cannot find by looking: the captain's words, text from other repos, where data lives, what is off limits.
- **Acceptance:** checks the worker can run itself. Name what stays unverified.
- **Limits:** where data and secrets stay, which services and directories to leave alone, how much CPU and memory to leave free.

## Workers in rex sessions

A worker that must outlive the coordinator's session runs in a rex session. The captain can attach to it.

- **Start:** `rex new <label> -c <repo dir> --keep-open --shell zsh -- claude --model <id> --permission-mode auto "<prompt>"`. Point the prompt at the brief.
- **Folder-trust prompt** (first run in a directory): `rex send-key -s <label> down enter`.
- **Read:** `rex capture -s <label> --trim | tail -40`.
- **Steer:** `rex send -s <label> '<text>' && rex send-key -s <label> enter`.
- **List and end:** `rex ls`, `rex kill <label>`.
- **Replace in place:** `rex window new -s <label> -c <repo dir> --keep-open --shell zsh -- claude --model <id> --permission-mode auto "<prompt>"` starts the replacement as a new window of the same session, so the label stays and no `<label>-2` appears. The new window becomes the active one, and `-s <label>` reads and steers the active window. Then close the old window: `rex window ls -s <label>`, `rex window close -s <label> <number>`. Add `-w <number>` to `capture`, `send` and `send-key` to address one window.
- **Paused by the captain:** resume only when the captain says so.
- **Context:** the status line shows the share used. At 20% used the worker hands off: a handoff comment on its brief, then its replacement as a new window of its own session.

Every Claude session of the account draws on one session limit: the coordinator, each worker and each worker's subworkers. Cap the workers so the limit holds until the reset, and tell each worker its cap.

## Watching

Arm a Monitor per worker and work on something else. A monitor lasts 30 minutes: re-arm on the expiry notice. A routine event gets one line to the captain.

Idle watch for a rex session. It emits the screen's tail once the screen stops changing for 3 minutes:

```sh
label=<label>; prev=""; same=0; told=0
while true; do
  if ! rex ls 2>/dev/null | grep -q "$label"; then echo "session $label is gone"; break; fi
  cur=$(rex capture -s "$label" --trim 2>/dev/null | tail -40 | sed -E 's/\([0-9hms ]+·[^)]*\)//' | md5sum)
  if [ "$cur" = "$prev" ]; then same=$((same+1)); else same=0; told=0; prev="$cur"; fi
  if [ $same -ge 6 ] && [ $told -eq 0 ]; then echo "screen unchanged for 3 min:"; rex capture -s "$label" --trim 2>/dev/null | tail -12 | cut -c1-160; told=1; fi
  sleep 30
done
```

## Research

Vendor docs, prices, web search and broad code search go to a spawned agent. Ask for a short table of facts with source URLs. This keeps the coordinator's context small.

## Review

Read every diff a worker merges or pushes. Report what you ran and what you only read. A worker's "tests pass" is its claim until you run them.

## Handoff

The captain switches sessions at about 20% of context used, which is about 200k tokens. The same threshold applies to the workers.

1. Rewrite the handoff file in place. It is the only one.
2. Move a lesson that will outlast the session into a skill, through a PR. Prune before adding.
3. Start the replacement with the prompt `/coordinate` as a new window of the rex session `coordinator` (a new session of that label if none exists), and tell the captain.
