---
name: search-sessions
description: Search past Claude Code sessions from every machine. Use when the user asks what was decided, said or found in an earlier session, or the answer may live in a past conversation rather than the repo.
---

`~/claude-sessions/<host>/` holds every machine's sessions, synced by Syncthing every 15 minutes. `cs` searches the user and assistant prose in them, and the plan-mode plans, ranked by relevance. It does not index tool calls or tool output.

## Steps

1. Search. Every term must match, and words are stemmed, so `deploy` finds `deploying`:

   ```sh
   cs smolvm networking
   ```

   Each result is one session: `<host>:<session-id>`, date, cwd, the best-matching snippet, and a `cs show` command. Use fewer or different terms when nothing matches. `-p potential-chainsaw` keeps sessions whose cwd contains that text, and `-n 50` returns more sessions.

2. Read the conversation around a hit by running its `cs show` line:

   ```sh
   cs show oci:76aeff0e-a19c-4272-acb2-c09865ec5670 --at 2026-11-07T15:44:55.172Z
   ```

   This prints from one turn before the hit to the end of the session. Drop `--at` for the whole session. The conclusion usually sits in the last assistant messages.

3. When the term would only appear in a command or its output (an error message, a file path), search the raw transcripts instead:

   ```sh
   rg -l -i -g '*.jsonl' 'ECONNREFUSED' ~/claude-sessions/*/projects
   ```

   The file name is the session id and its first path segment is the host, so read it with `cs show <host>:<session-id>`.

4. Report the answer, then cite each source as `<host>:<session-id>` with the session's date, so the user can `claude --resume <session-id>` on that host.

Done when the answer is backed by quoted text from a transcript, or `cs` and `rg` both came up empty.
