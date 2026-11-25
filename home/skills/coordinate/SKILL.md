---
name: coordinate
description: Coordinator runbook for any project. Use when the captain says "you are the coordinator", asks you to steer other agents, or asks for a handoff.
---

# Coordinating

The captain owns decisions. The coordinator's job is judgment: pick work, brief it, steer the workers, review, report, hand off.

The captain follows from the mobile app, and PushNotification does not reach them. Put every ask in the chat reply. A `!` command for the captain is one short line with `~` paths. The captain may type into a worker's pane while attached; treat that as the captain's instruction.

When the project has its own `coordinate-*` skill, load it too. It holds the project's pipeline, deploy and state. This skill holds what is the same in every project.

## State

One handoff file per project, on the host and outside the repo: `~/.local/share/<project>/coordinator-handoff.md`. It holds what the next coordinator cannot read from the repo or the issues: what runs now and where, next steps in order, decisions waiting on the captain with a recommendation each, what is found but not filed. Keep it under 10 KB: every coordinator reads it whole at start. Move history to a dated archive file and running tallies to their issue.

Decisions go on the issue or into an ADR. Lessons that outlast the session go into a skill, through a PR.

## Start of a session

1. Read the handoff file and the repo's `AGENTS.md`.
2. Check CI on the default branch, open issues and open PRs.
3. Find what still runs: `rex ls`, `treehouse status` in each repo for leased worktrees, background monitors, unmerged branches. Arm a watch on each running worker first.
4. Decide what is reversible and inside the captain's delegation, and post it on the issue. Ask the captain only about money, secrets, irreversible actions and product direction, each with a recommendation, then say what you do next.

## Briefs

A brief is cut from a spec issue that states the user's end-to-end flow. A brief that changes the flow updates the spec first. A brief is one worker's work order: a GitHub issue, or a comment on one, with the sections Decisions, Facts, Acceptance, Out of scope.

- **Decisions:** every choice the worker would otherwise stop to ask about. Mark which are the captain's and which are yours, and tell the captain yours.
- **Facts:** what the worker cannot find by looking: the captain's words, text from other repos, where data lives, what is off limits.
- **Acceptance:** checks the worker can run itself. Name what stays unverified.
- **Limits:** where data and secrets stay, which services and directories to leave alone, how much CPU and memory to leave free.

## Workers in rex sessions

A worker that must outlive the coordinator's session runs in a rex session. The captain can attach to it.

- **Worktree:** in the repo, `treehouse get --lease -b <branch> --lease-holder <label>` leases a worktree on a new branch and prints its path. Pass that path as `-c` below, and tell the worker to work there and create no worktree of its own. The lease holds until `treehouse return <path>`.
- **Start:** `sid=$(uuidgen)`, then `rex new <label> -c <worktree path> --keep-open --shell zsh -- zsh -lic "claude --model <id> --permission-mode auto --disallowedTools AskUserQuestion --session-id $sid '<prompt>'"`. Keep `$sid`: the worker's transcript is `~/.claude/projects/<worktree path with / and . replaced by ->/$sid.jsonl`. `--disallowedTools` takes several values, so keep another flag between it and the prompt. Point the prompt at the brief and end it with the question rule below. The login shell puts `claude` on PATH; a bare `-- claude` fails with "command not found". `rex new` has no `--focus` flag and leaves the captain's app view where it is.
- **Address by ID:** a SessionStart hook tells each Claude session to rename its own rex session, so the label given to `rex new` does not last. Add `--json` to `rex new` and keep `.session_id` and `.initial_windows[0].block_ids[0]`. Pass the session ID, or its last 6 characters from `rex ls`, as `-s` in every command below. The watch needs the block ID.
- **Folder-trust prompt** (first run in a directory): `rex send-key -s <label> down enter`.
- **Question rule** (end every worker prompt with it): "When you need a decision the brief does not make, end your turn with the question as your final message: what you found, the options, and the one you recommend. Wait for the answer. If auto mode denies an action, report the action and the reason the same way, and do not retry it."
- **Read:** the worker's last messages, from its transcript: `jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text' <transcript> | tail -40`. The file can lag by a moment, so read it again when the turn looks cut short. Claude Code's fullscreen TUI has no scrollback, so `rex capture -s <label> --trim | tail -40` shows only the current screen. Use it for what the transcript does not hold: the folder-trust prompt, a permission prompt, a login.
- **Steer or answer:** `rex send -s <label> '<text>' && rex send-key -s <label> enter`. Answer with the chosen option's words and any facts the worker lacked. Text sent during a busy turn can be lost: confirm it in the transcript's user messages. Grey text in the input box is Claude Code's suggested prompt, not the captain's typing; sent text replaces it. Put long instructions in an issue or PR comment and send a pointer to it.
- **Denied actions:** an auto-mode denial is the captain's call. Never approve it by typing into the worker, and do not retry it from your own session. Tell the captain the action, the reason and your recommendation. The captain runs it with `!` in a session or adds an allow rule.
- **List and end:** `rex ls`, `rex kill <label>`. Once the branch is merged or abandoned, release the worktree with `treehouse return <worktree path>`, then delete the branch with `git branch -d <branch>`, which the return keeps.
- **Replace in place:** `rex window new -s <label> -c <worktree path> --focus=false --keep-open --shell zsh --json -- zsh -lic "claude --model <id> --permission-mode auto --disallowedTools AskUserQuestion --session-id $sid '<prompt>'"` (a new `sid`) starts the replacement as a new window of the same session, so the label stays and no `<label>-2` appears. `--focus=false` keeps the old window active, so a captain viewing the session stays where they are. Close the old window with `rex window ls -s <label>` and `rex window close -s <label> <number>`; the replacement then becomes the active window, and `-s <label>` reads and steers it. Add `-w <number>` to `capture`, `send` and `send-key` to address one window. Arm the watch on the new `.block_ids[0]`.
- **Paused by the captain:** resume only when the captain says so.
- **Context:** the status line shows the share used. At 20% used the worker hands off: a handoff comment on its brief, then its replacement as a new window of its own session.

Every Claude session of the account draws on one session limit: the coordinator, each worker and each worker's subworkers. Cap the workers so the limit holds until the reset, and tell each worker its cap.

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

A worker that waits on background runs ends a turn at every wait, so each wait prints `done:`. For such a worker, pipe the watch through a filter: on `done:`, read the transcript's last text and print it only when it matches `\?|pull/|PR #|opened|decision|recommend|denied`.

A program other than Claude Code may report no status. Check with `rex api call com.superlogical.terminal.program_status '{"session_id":"<id>","block_id":"<id>","args":{}}'`, which then returns no records. For such a program, fall back to a screen hash. Every 30 s, hash `rex capture -s <id> --trim | tail -40`, and print the tail once the hash stays the same for 3 minutes. Stop when the session leaves `rex ls`.

## Research

Vendor docs, prices, web search and broad code search go to a research worker in its own rex session, not to an in-process subagent and not inline. The captain can attach to a rex session and steer it, it outlives the coordinator, and the coordinator's context stays small.

Before researching, search past sessions (`search-sessions` skill) and sibling repos' issues for the same question.

- Ask for a short table of facts with source URLs.
- Name where the report goes: an issue comment or a file. A rex session returns nothing to the coordinator by itself.
- Arm a watch on it, read the report on `done`, then end the session.

## Review

Read every diff a worker merges or pushes. Report what you ran and what you only read. A worker's "tests pass" is its claim until you run them.

## Handoff

At about 20% of context used (about 200k tokens), hand off without asking. The same threshold applies to the workers.

1. Rewrite the handoff file in place. It is the only one.
2. Move a lesson that will outlast the session into a skill, through a PR. Prune before adding.
3. Start the replacement with the prompt `/coordinate` as a new window of the rex session `coordinator` (a new session of that label if none exists), and tell the captain. Do not kill the old session: auto mode denies it. Give the captain `! rex kill <id>`.
