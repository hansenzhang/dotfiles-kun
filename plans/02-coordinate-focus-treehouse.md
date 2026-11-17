# 02 coordinate: background focus and treehouse worktrees

Brief for the worker that did 01, continuing on branch `coordinate-program-status` in `~/github/dotfiles-kun-cps`. Delete this file in the commit that finishes it.

## Decisions

- Every `rex new` and `rex window new` in `home/skills/coordinate/SKILL.md` gets `--focus=false`. (Coordinator's call.)
- Host workers get their worktree from treehouse, not `git worktree add`. The coordinator acquires it and passes the path as `-c`; the worker does not create its own. (Captain's call.)
- Acquire: `treehouse get --lease -b <branch> --lease-holder <session label>`, run in the repo; it prints the path. Release with `treehouse return <path>` after the branch is merged or abandoned, never with unlanded work in it.
- Add one line to the skill's "Start of a session" step 3: list held worktrees with `treehouse status` next to `rex ls`.
- Keep the change to the skill and its helper files. No wrapper script.

## Facts

- Cause of the bug: `rex new` without `--focus=false` moves the captain's app window to the new session. During brief 01 the captain's window followed `cps-test`, and the `rex kill` on it closed that window. The captain had to reopen their coordinator session.
- treehouse is at `~/.local/bin/treehouse`. See `treehouse get --help`, `return --help`, `status --help`. A leased slot is never handed out again or pruned until `treehouse return`.
- Existing stale slot: `~/.treehouse/dotfiles-kun-db9e1c/1` (detached HEAD). Leave it alone; report it.
- Prior art: firstmate uses treehouse for crew worktrees (https://github.com/kunchenguid/firstmate, `docs/architecture.md`).

## Acceptance

- Start a haiku test worker exactly as the updated skill says (`--focus=false`, treehouse lease). Confirm the captain's focused session did not change: `rex whoami --json` or the client's focused session before and after. Then `rex kill` it and `treehouse return` its path; `treehouse status` shows the slot available.
- Run `unslop` and `writing-for-agents` on the skill change.
- Commit on `coordinate-program-status`. Then merge into `main` in `~/github/dotfiles-kun` (fast-forward if possible). Do not push. Leave the unrelated uncommitted `home/.claude/settings.json` change in main untouched. Delete the untracked `plans/` copies in the main checkout after the merge.
- Remove the `~/github/dotfiles-kun-cps` worktree and the merged branch after the merge.
- Report: commit shas, the focus check result, and anything unverified.

## Out of scope

- super-enigma's `coordinate-swarm` skill.
- Running `darwin-rebuild` or `reload`; the captain does that.
