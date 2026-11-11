---
name: search-sessions
description: Search past Claude Code sessions from every machine. Use when the user asks what was decided, said or found in an earlier session, or the answer may live in a past conversation rather than the repo.
---

`~/claude-sessions/<host>/` holds every machine's sessions, synced by Syncthing every 15 minutes:

- `projects/<project-dir>/<session-id>.jsonl` is one transcript, one JSON event per line. `<project-dir>` is the session's cwd with `/` replaced by `-`.
- `history.jsonl` lists every prompt the user typed, with `project` and `timestamp`.
- `plans/` holds plan-mode plans as markdown.

## Steps

1. Find candidate sessions by file name. Search every host, since the session may have run elsewhere:

   ```sh
   rg -l -i -g '*.jsonl' -g '*.md' 'smolvm' ~/claude-sessions/*/projects ~/claude-sessions/*/plans
   ```

   Narrow with more terms or a project dir glob when the list is long. Worktree sessions get dirs like `-home-hansen--treehouse-<repo>-<id>-<repo>`, so glob on the repo name: `~/claude-sessions/*/projects/*potential-chainsaw*`. Newest first: pipe through `xargs ls -t`.

2. Read the conversation text of each candidate, without tool output:

   ```sh
   jq -r 'select(.type=="user" or .type=="assistant")
     | .message.content | if type=="string" then . else map(select(.type=="text").text) | join("\n") end
     | select(length>0)' FILE.jsonl
   ```

   Pipe through `rg -i -C5 TERM` to jump to the hits. The conclusion usually sits in the last assistant messages, so check the tail too.

3. Report the answer, then cite each source as `<host>:<session-id>` with the session's date, so the user can `claude --resume <session-id>` on that host.

Done when the answer is backed by quoted text from a transcript, or every host's archive was searched and came up empty.
