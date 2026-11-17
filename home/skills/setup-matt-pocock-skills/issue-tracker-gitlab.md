# Issue tracker: GitLab

This repo's issues and specs are GitLab issues. Use the [`glab`](https://gitlab.com/gitlab-org/cli) CLI for every operation.

## Commands

- Create an issue with `glab issue create --title "..." --description "..."`. Pass a multi-line description through a heredoc, or pass `--description -` to open an editor.
- Read an issue with `glab issue view <number> --comments`. Add `-F json` for JSON output.
- List issues with `glab issue list -O json`, adding `--label` filters as needed.
- Comment with `glab issue note <number> --message "..."`. GitLab calls comments "notes".
- Add or remove labels with `glab issue update <number> --label "..."` or `--unlabel "..."`. Separate several labels with commas or repeat the flag.
- Close an issue by posting the explanation with `glab issue note <number> --message "..."` and then running `glab issue close <number>`, which takes no comment.
- GitLab calls pull requests "merge requests". `glab mr create`, `glab mr view`, `glab mr note` and the rest work like `gh pr ...`, with `mr` for `pr` and `note --message` for `comment --body`.

`glab` reads the repo from `git remote -v` when it runs inside a clone.

## Merge requests in triage

**MRs as a request surface: no.** _(Set this to `yes` if this repo treats outside merge requests as feature requests. `/triage` reads this setting.)_

When it is `yes`, MRs go through the same labels and states as issues, with the `glab mr` commands:

- Read an MR with `glab mr view <number> --comments`, and `glab mr diff <number>` for the diff.
- List outside MRs for triage with `glab mr list -O json`, then keep only MRs whose author is not a project member or owner.
- Comment, label, and close with `glab mr note`, `glab mr update --label` or `--unlabel`, and `glab mr close`.

GitLab numbers issues and MRs separately, so `#42` is unambiguous once you know which one the maintainer means.

## When a skill says "publish to the issue tracker"

Create a GitLab issue.

## When a skill says "fetch the relevant ticket"

Run `glab issue view <number> --comments`.

## Wayfinder operations

`/wayfinder` uses these. The map is one issue, and each ticket is a child issue of it.

- The map is an issue labelled `wayfinder:map`, whose description holds the Notes, Decisions so far, and Not yet specified sections. Create it with `glab issue create --label wayfinder:map`. On GitLab tiers with epics, an epic can hold the map instead, but a labelled issue works on every tier.
- A child ticket is an issue with `Part of #<map>` at the top of its description, linked to the map with `glab issue create --linked-issues <map> --link-type relates_to`. Each ticket has one `wayfinder:<type>` label, where the type is `research`, `prototype`, `grilling`, or `task`. A claimed ticket is assigned to the developer driving the map.
- Record blocking with GitLab's native blocking link, which the GitLab UI shows. Add it by posting the `/blocked_by #<n>` quick action as a note: `glab issue note <child> --message "/blocked_by #<blocker>"`. Blocking links need GitLab Premium or Ultimate. On other tiers, put a `Blocked by: #<n>, #<n>` line at the top of the description. A ticket is unblocked when every blocker is closed.
- To find the frontier, list the map's children with `glab api projects/:id/issues/<map>/links` and keep the open issues that have a `wayfinder:<type>` label. Drop any that has an assignee or an open blocker, either a native `blocked_by` link to an open issue (`glab api projects/:id/issues/<child-iid>/links`) or an open issue in its `Blocked by` line. The first remaining child in map order is next.
- Claim a ticket with `glab issue update <n> --assignee @me`. This is the session's first write.
- Resolve a ticket with `glab issue note <n> --message "<answer>"`, then `glab issue close <n>`. Then add a line to the map's Decisions so far with a one-line summary and a link.
