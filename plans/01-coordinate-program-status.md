# 01 coordinate: watch workers through rex program status

Brief for one worker session. Delete this file in the commit that finishes it.

Goal: replace the md5 screen-hash idle watch in `home/skills/coordinate/SKILL.md` with rex native program status.

The `coordinate` skill (`home/skills/coordinate/SKILL.md`) detects a finished or stuck worker by hashing the screen tail every 30 s and alerting after 3 min without change. That heuristic cannot tell done from blocked on a prompt from rate-limited, adds up to 3 min of latency, and every alert costs the coordinator a screen capture read into context.

Claude Code already reports its state to rex through OSC 7501. Rex exposes it as `com.superlogical.terminal.program_status` and streams changes as `terminal.program_status_changed`. Replace the md5 loop with that signal.

## Decisions

- Signal source: rex's native program status, not a new Claude Code hook. Claude Code emits it today; a hook would duplicate it. (Coordinator's call.)
- Watch mechanism: a bounded `rex do` Lua reader subscribed to `terminal.program_status_changed`, `terminal.child_exited` and `block_closed` for the worker's block, run under Monitor. Subscribe first, then read the current status once, so an edge between the two is not lost.
- Wake only on `blocked` (with its `kind`: `permission`, `question`, `auth`), `done`, `error`, `idle` after `working`, or the block or program ending. `working` updates stay silent.
- Emit one line per wake (state, kind, msg cut to 160 chars). The coordinator runs `rex capture` only when it decides to look, not on every wake.
- Keep the md5 loop as a documented fallback for programs that report no status.

## Facts

- Probe from a Claude Code 2.1.326 block under rex 0.1.0-preview.14 (API revision 12):
  `rex api call com.superlogical.terminal.program_status '{"session_id":"<session>","block_id":"<block>","args":{}}'`
  returned `{"records":[{"state":"working","app":"claude-code","msg":"<current task>", "owner":{"pid":...}}]}`.
- States: `idle`, `working`, `done`, `blocked`, `error` (unknown means `idle`). `kind` on blocked: `permission`, `question`, `auth`.
- `rex block ls --json` does not include program status; use the API method or the event.
- Prior art: firstmate's Rex adapter reader, https://github.com/kunchenguid/firstmate/blob/main/bin/backends/rex-eventwait.lua, and its "Push events" section in `docs/rex-backend.md`. It filters records by foreground process to ignore a child program's status; check whether that is needed here.
- Context matters: firstmate's supervisor burned context on message passing and pane reads. The goal is fewer, typed wakes, not more output.

## Acceptance

- The skill's "Watching" section uses the reader; the md5 loop is reduced to a fallback paragraph.
- Manual check, recorded on this issue: start a worker with `rex new`, then observe one wake each for (1) a permission prompt (`blocked`/`permission`), (2) the turn ending (`idle` or `done`), (3) `rex kill` (block gone). Record the latency of each.
- No wake while the worker is only `working`.
- Run `unslop` and `writing-for-agents` on the skill change.

## Out of scope

- super-enigma's `coordinate-swarm` DB watch (pipeline goals already have typed state in SQLite).
- Replacing rex with T3 Code's `t3 thread` / MCP `t3_thread_wait`. Revisit if provider switching or forks become needed.
- A rate-limit state: check what Claude Code reports on a session-limit message and note it here; a separate issue if it reports nothing useful.

## Limits

- Work on branch `coordinate-program-status` in a git worktree (`git worktree add ../dotfiles-kun-cps -b coordinate-program-status`). Commit there; do not push, do not merge, do not run `darwin-rebuild` or `reload`.
- Put any helper script (the Lua reader) under `home/skills/coordinate/`, next to SKILL.md.
- Test workers you start with `rex new`: use a haiku model, a trivial prompt, and `rex kill` them when done.
- Report results (wakes observed, latencies, commit sha) as your final message and in the commit body.
