# global agent instructions

- Never use the em dash "—". Use plain dash "-" instead
- When writing commit messages, NEVER auto-add your agent name as co-author
- Never manually modify CHANGELOG.md files or any files that are marked as auto-generated
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- For one-off or infrequent operational work, start with the simplest direct end-to-end path. Do not build wrappers, control planes, policy layers, custom verifiers, or automation unless the direct path exposes a concrete blocker or repeated need that justifies the added machinery.
- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it as possible.
  This makes sure you find the real problem so your fix will actually solve it.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection.
  If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed.
- Before using "dynamic workflows", "ultra code" or any harness feature that immediately spawns a large swarm of subagents, always explain the tradeoffs and ask the user for explicit approval.

## Working rules

- Architecture before code. For a new module, write or update its design note first. Keep one `.md` per module next to the code (or under `docs/modules/`) and update it in the same commit.
- Work from briefs. When a prompt points at a brief (plans/NN, tasks/NNN, a design-doc phase, a GitHub issue), its acceptance criteria are the definition of done. When finished, append an "As built (date)" note to the brief: what changed, commits, measurements, open follow-ups.
- Verification. Say which acceptance checks you ran and which need me (device, production, my real data). Never report a check as done that you could not run.
- Parallel sessions. Other sessions may be working in this checkout. Stage and commit only the files you changed (`git add <paths>`, never `-A`), or work in a worktree.
- Commits. Follow the repo's CLAUDE.md or AGENTS.md commit and push policy. If it has none, commit only when asked, and write a body that says why.
- Commit times. No commit may carry an author or committer date between 08:00 and 18:00 local time, Monday to Friday. If you commit (or amend, rebase, cherry-pick) inside that window, set both dates to the same day from 18:00 on, later than HEAD's dates and a few minutes apart per commit, e.g. `GIT_AUTHOR_DATE="2026-10-28T18:05:00" GIT_COMMITTER_DATE="2026-10-28T18:05:00" git commit ...`. Check with `git log -1 --format='%ai %ci'`.
- Decisions go in the repo (ADR or design doc, dated), not in memory. Memory is for facts about me and this machine.
- In someone else's repo, keep notes outside it, and check `git log` before stating what the repo contains.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
