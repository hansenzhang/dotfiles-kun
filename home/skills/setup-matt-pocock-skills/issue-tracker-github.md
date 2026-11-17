# Issue tracker: GitHub

This repo's issues and specs are GitHub issues. Use the `gh` CLI for every operation.

## Commands

- Create an issue with `gh issue create --title "..." --body "..."`. Pass a multi-line body through a heredoc.
- Read an issue with `gh issue view <number> --json number,title,body,labels,comments`.
- List issues with `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'`, adding `--label` and `--state` filters as needed.
- Make an issue a sub-issue of a parent with `gh issue create --parent <parent> ...`, or afterwards with `gh issue edit <parent> --add-sub-issue <child>` (`gh` 2.94 or later). With an older `gh`, run `gh api --method POST repos/<owner>/<repo>/issues/<parent>/sub_issues -F sub_issue_id=<child-db-id>`, which takes the database id described under blocking below. If the repo has no sub-issues, put `Part of #<parent>` at the top of the child's body.
- Record blocking with GitHub's native issue dependencies, which the GitHub UI shows. Add an edge with `gh issue create --blocked-by <n>,<n> ...` or `gh issue edit <child> --add-blocked-by <blocker>` (`gh` 2.94 or later). With an older `gh`, run `gh api --method POST repos/<owner>/<repo>/issues/<child>/dependencies/blocked_by -F issue_id=<blocker-db-id>`. `<blocker-db-id>` is the blocker's numeric database id from `gh api repos/<owner>/<repo>/issues/<n> --jq .id`, not its `#number` or `node_id`. If dependencies are unavailable, put a `Blocked by: #<n>, #<n>` line at the top of the child's body instead. A ticket is unblocked when every blocker is closed.
- Count open blockers with `gh api repos/<owner>/<repo>/issues/<n> --jq .issue_dependencies_summary.blocked_by`. It counts only open blockers, so 0 means the ticket can start. `gh issue view <n> --json blockedBy` also lists closed blockers, so filter it with `--jq '[.blockedBy.nodes[] | select(.state == "OPEN")] | length'`.
- Comment with `gh issue comment <number> --body "..."`.
- Add or remove a label with `gh issue edit <number> --add-label "..."` or `--remove-label "..."`.
- Close an issue by posting the explanation with `gh issue comment <number> --body "..."` and then running `gh issue close <number>`. Don't use `gh issue close --comment` on an issue that is already closed: it drops the comment and still exits 0.

`gh` reads the repo from `git remote -v` when it runs inside a clone.

File issues only in the user's own repo. Never file in `mattpocock/skills`, the repo these skills came from, unless the user owns it. In a fork, `gh` can default to the upstream parent. Before the first `gh issue create` of a session, check the target with `gh repo view --json nameWithOwner`, and confirm with the user if it isn't their repo.

## Pull requests in triage

**PRs as a request surface: no.** _(Set this to `yes` if this repo treats outside PRs as feature requests. `/triage` reads this setting.)_

When it is `yes`, PRs go through the same labels and states as issues, with the `gh pr` commands:

- Read a PR with `gh pr view <number>`, then `gh pr view <number> --comments`, and `gh pr diff <number>` for the diff. Outside a TTY, `--comments` prints only the comments, not the body.
- List outside PRs for triage with `gh api --paginate 'repos/{owner}/{repo}/pulls?state=open' --jq '.[] | select(.author_association | IN("OWNER","MEMBER","COLLABORATOR") | not) | {number, title, author: .user.login, author_association, labels: [.labels[].name]}'`.
- Comment, label, and close with `gh pr comment`, `gh pr edit --add-label` or `--remove-label`, and `gh pr close`.

Issues and PRs share one number space on GitHub, so `#42` may be either. Try `gh pr view 42`, and if that fails, `gh issue view 42`.

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Read the issue with the command above.

## Wayfinder operations

`/wayfinder` uses these. The map is one issue, and each ticket is a child issue of it.

- The map is an issue labelled `wayfinder:map`, whose body holds the Notes, Decisions so far, and Not yet specified sections. Create it with `gh issue create --label wayfinder:map`.
- A child ticket is a sub-issue of the map, created as described above. If the repo has no sub-issues, add the child to a task list in the map's body and put `Part of #<map>` at the top of the child's body. Each ticket has one `wayfinder:<type>` label, where the type is `research`, `prototype`, `grilling`, or `task`. A claimed ticket is assigned to the developer driving the map.
- Blocking works as described above.
- To find the frontier, list the map's open children with `gh issue list --state open`, limited to the map's sub-issues or task list. Drop any child that has an assignee or an open blocker, either a native one or an open issue in its `Blocked by` line. The first remaining child in map order is next.
- Claim a ticket with `gh issue edit <n> --add-assignee @me`. This is the session's first write.
- Resolve a ticket with `gh issue comment <n> --body "<answer>"`, then `gh issue close <n>`. Then add a line to the map's Decisions so far with a one-line summary and a link.
