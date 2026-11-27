---
name: coordinate
description: Coordinator runbook for any project. Use when the captain says "you are the coordinator", asks you to steer other agents, or asks for a handoff.
---

# Coordinating

The captain owns decisions. The coordinator's job is judgment: pick work, brief it, steer the workers, review, report, hand off.

The captain follows from the mobile app, and PushNotification does not reach them. Put every ask in the chat reply. A `!` command for the captain is one short line with `~` paths. The captain may type into a worker's pane while attached; treat that as the captain's instruction.

When the project has its own `coordinate-*` skill, load it too. It holds the project's pipeline, deploy and state. This skill holds what is the same in every project.

## State

One coordinator per project at a time. Before starting, check `rex ls` for another coordinator on the same project; two coordinators appending to one handoff file overflow it.

One rex session per project holds the coordinator and its workers, each in its own tab (a rex window). Name the session `<repo>/coordinate` with `rex session rename "$REX_SESSION" <repo>/coordinate`, and your tab `coordinator` with `rex window rename -s "$REX_SESSION" <window-id> coordinator`; `rex block inspect "$REX_BLOCK" --json` gives your window ID as `.block.window_id`. A coordinator outside rex creates the session with `rex new <repo>/coordinate --json` and uses its `.session_id` wherever this skill says `$REX_SESSION`.

One handoff file per project, on the host and outside the repo: `~/.local/share/<project>/coordinator-handoff.md`. It holds what the next coordinator cannot read from the repo or the issues: what runs now and where, next steps in order, decisions waiting on the captain with a recommendation each, what is found but not filed. Keep it under 10 KB: every coordinator reads it whole at start. Rewrite it, never append to it. State for paused work goes to a side file next to it, named in one line of the handoff file and read only when that work resumes. Move history to a dated archive file and running tallies to their issue.

Decisions go on the issue or into an ADR. Lessons that outlast the session go into a skill, through a commit to the repo that holds it.

## Start of a session

1. Read the handoff file and the repo's `AGENTS.md`.
2. Check CI on the default branch, open issues and open PRs.
3. Find what still runs: `rex ls`, `rex window ls -A`, `treehouse status` in each repo for leased worktrees, background monitors, unmerged branches. Arm a watch on each running worker first. Report each lease that no running worker and no paused brief holds, with its branch and whether it has unpushed commits, and give the captain the `treehouse return` line for it.
4. Decide what is reversible and inside the captain's delegation, and post it on the issue. Ask the captain only about money, secrets, irreversible actions and product direction, each with a recommendation, then say what you do next.

## Briefs

A brief is cut from a spec issue that states the user's end-to-end flow. A brief that changes the flow updates the spec first. A brief is one worker's work order: a GitHub issue, or a comment on one, with the sections Decisions, Facts, Acceptance, Out of scope. When the project's tracker is not GitHub, or the work is local only, the project's `coordinate-*` skill names where briefs live instead. Delete or close a brief when its work ships.

A brief covers one phase. When the captain adds a phase, write a new brief and start a fresh worker for it with **Replace in place** below; do not append the phase to a running brief.

- **Decisions:** every choice the worker would otherwise stop to ask about. Mark which are the captain's and which are yours, and tell the captain yours.
- **Facts:** what the worker cannot find by looking: the captain's words, text from other repos, where data lives, what is off limits.
- **Acceptance:** checks the worker can run itself. Name what stays unverified. A brief that ends in a PR includes the `pr-polish` author pass.
- **Limits:** where data and secrets stay, which services and directories to leave alone, how much CPU, memory and disk to leave free. Build caches can fill a disk in hours: check free disk space whenever a worker builds.

## Workers in rex tabs

A worker that must outlive the coordinator runs in a tab of the project's rex session. The captain can attach to it.

- **Worktree:** in the repo, `treehouse get --lease -b <branch> --lease-holder <label>` leases a worktree on a new branch and prints its path. Pass that path as `-c` below, and tell the worker to work there and create no worktree of its own. The lease holds until `treehouse return <path>`. One worker per worktree: never start a second worker in a leased path.
- **Start:** `sid=$(uuidgen)`, then `rex window new <label> -s "$REX_SESSION" -c <worktree path> --focus=false --keep-open --shell zsh --json -- zsh -lic "claude --model <id> --permission-mode auto --disallowedTools AskUserQuestion --session-id $sid '<prompt>'"`. Keep `$sid`: the worker's transcript is `~/.claude/projects/<worktree path with / and . replaced by ->/$sid.jsonl`. `--disallowedTools` takes several values, so keep another flag between it and the prompt. `<label>` names the tab, which is what the captain reads, so make it say what the worker does. Point the prompt at the brief and end it with the question rule below. The login shell puts `claude` on PATH; a bare `-- claude` fails with "command not found". `--focus=false` leaves a captain viewing the session where they are.
- **Address by ID:** keep `.window_id` and `.block_ids[0]` from the `--json` output. Pass `-s "$REX_SESSION" -b <block-id>` to `capture`, `send` and `send-key`; without `-b` they act on whichever tab is focused.
- **Folder-trust prompt** (first run in a directory): `rex send-key -s "$REX_SESSION" -b <block-id> down enter`.
- **Question rule** (end every worker prompt with it): "When you need a decision the brief does not make, end your turn with the question as your final message: what you found, the options, and the one you recommend. Wait for the answer. If auto mode denies an action, report the action and the reason the same way, and do not retry it."
- **Read:** the worker's last messages, from its transcript: `jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' <transcript> | tail -40`. The file can lag by a moment, so read it again when the turn looks cut short. Claude Code's fullscreen TUI has no scrollback, so `rex capture -s "$REX_SESSION" -b <block-id> --trim | tail -40` shows only the current screen. Use it for what the transcript does not hold: the folder-trust prompt, a permission prompt, a login.
- **Steer or answer:** `rex send -s "$REX_SESSION" -b <block-id> '<text>' && rex send-key -s "$REX_SESSION" -b <block-id> enter`. Answer with the chosen option's words and any facts the worker lacked. Text sent during a busy turn can be lost: confirm it in the transcript's user messages. Grey text in the input box is Claude Code's suggested prompt, not the captain's typing; sent text replaces it. Put long instructions in an issue or PR comment and send a pointer to it.
- **Denied actions:** an auto-mode denial is the captain's call. Never approve it by typing into the worker, and do not retry it from your own session. Tell the captain the action, the reason and your recommendation. The captain runs it with `!` in a session or adds an allow rule. A permission prompt on a worker's screen is the captain's call too: do not accept or decline it with keys.
- **List and end:** `rex window ls -s "$REX_SESSION"`, `rex window close -s "$REX_SESSION" <window-id>`. Never `rex kill` the project's session: it ends every tab. Once the branch is merged or abandoned, release the worktree with `treehouse return <worktree path>`, then delete the branch with `git branch -d <branch>`, which the return keeps.
- **Replace in place:** run the **Start** command again with a new `sid`, the same label and the same worktree path. Close the old tab by its window ID, then arm the watch on the new `.block_ids[0]`.
- **Paused by the captain:** resume only when the captain says so.
- **Context:** the status line shows the share used. At 20% used the worker hands off: a handoff comment on its brief, then its replacement in a new tab. Auto-compaction is not a handoff. When a worker's transcript shows a compaction, replace it in place.

## Usage limits

Every Claude session of the account draws on one 5-hour limit and one weekly limit: the coordinator, each worker and each worker's subagents.

- An interactive `claude` in a rex tab waits at the limit and continues by itself at the reset. The watch prints `error:`; do nothing and do not send "continue".
- An in-process subagent (Agent tool) dies at the limit with "Agent terminated early" and is never resumed. Start it again after the reset.
- Cap the workers so both limits hold until the captain's deadline, and tell each worker its cap. Check the weekly share left before starting long Opus runs; when it cannot hold, ask the captain which work to drop.

## Watching

Arm a Monitor per worker and work on something else. Never run a foreground `sleep` before a check: the harness blocks it. A monitor lasts 30 minutes: re-arm on the expiry notice. A routine event gets one line to the captain.

Claude Code reports its state to rex, and `watch.lua` (next to this file) turns that into one line per event that needs the coordinator:

```sh
rex do -s <session-id> --for 30m ~/.claude/skills/coordinate/watch.lua block=<block-id>
```

| Line | Meaning |
| --- | --- |
| `blocked/permission: <msg>` | Waits on a tool approval. `<msg>` names the command. |
| `blocked/question: <msg>`, `blocked/auth: <msg>`, `blocked: <msg>` | Waits on an answer, a login or an open dialog. |
| `done: <msg>` | The turn ended. Read the last messages: a result, or a question under the question rule. |
| `idle: <msg>` | The turn was cancelled. |
| `error: <msg>` | The turn ended on an error, such as a session limit. `<msg>` is the error text. |
| `gone: <why>` | The program exited or the block closed. The watch ends. |

Updates while the worker is `working` print nothing. On arming, the watch prints the current state once if it is `blocked`, `done` or `error`. Read the transcript only when a line calls for a look.

A worker that waits on background runs ends a turn at every wait, so each wait prints `done:`. For such a worker, use `watch-filtered.sh` (next to this file) as the Monitor command: it prints a `done:` line only when the worker's last text looks like a result or a question.

```sh
~/.claude/skills/coordinate/watch-filtered.sh <session-id> <block-id> <transcript>
```

A program other than Claude Code may report no status. Check with `rex api call com.superlogical.terminal.program_status '{"session_id":"<id>","block_id":"<id>","args":{}}'`, which then returns no records. For such a program, fall back to a screen hash. Every 30 s, hash `rex capture -s <id> -b <block-id> --trim | tail -40`, and print the tail once the hash stays the same for 3 minutes. Stop when the block leaves `rex block ls -s <id>`.

## Research

Vendor docs, prices, web search and broad code search go to a research worker in its own rex tab, not to an in-process subagent and not inline. The captain can attach to the tab and steer it, it outlives the coordinator, and the coordinator's context stays small.

Before researching, search past sessions (`search-sessions` skill) and sibling repos' issues for the same question.

- Ask for a short table of facts with source URLs.
- Name where the report goes: an issue comment or a file. A rex tab returns nothing to the coordinator by itself.
- Arm a watch on it, read the report on `done`, then close the tab.

## Review

Read every diff a worker merges or pushes. Report what you ran and what you only read. A worker's "tests pass" is its claim until you run them.

Before a PR merges, or before a local-only branch is called done, two reviewers run in a fresh context, each as an in-process subagent given only the PR number or branch and the brief's link:

- the `pr-polish` reviewer pass, for cruft;
- `/code-review high` on the same diff, for correctness. pr-polish does not look for bugs.

They are short and read-only, so they need no rex tab; one that dies at a usage limit is started again after the reset. Send their findings to the worker, then rerun the tests on the fixed head. When the captain asks for the same cleanup on two PRs, that request is a missing rule: add it to `pr-polish` through a PR.

## Handoff

At about 20% of context used (about 200k tokens), hand off without asking. The same threshold applies to the workers. A coordinator that has been compacted is past it: hand off now.

1. Rewrite the handoff file in place, with side files only for paused work (see State).
2. Move a lesson that will outlast the session into a skill. Prune before adding.
3. Start the replacement with the prompt `/coordinate` in a new `coordinator` tab of the project's session, using the **Start** command, and tell the captain. Do not close your own tab: auto mode denies ending the old coordinator. Give the captain `! rex window close -s <session-id> <window-id>`, with your own window ID.
