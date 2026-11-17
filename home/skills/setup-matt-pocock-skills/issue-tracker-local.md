# Issue tracker: local markdown

This repo's issues and specs are markdown files under `.scratch/`.

## Layout

- Each feature has its own directory, `.scratch/<feature-slug>/`.
- The spec is `.scratch/<feature-slug>/spec.md`.
- Each implementation ticket is its own file, `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`. Never put several tickets in one file.
- A `Status:` line near the top of each issue file holds its triage state. `triage-labels.md` lists the role strings.
- Comments go at the bottom of the file under a `## Comments` heading, oldest first.

## When a skill says "publish to the issue tracker"

Create a file under `.scratch/<feature-slug>/`, and create the directory if it doesn't exist.

## When a skill says "fetch the relevant ticket"

Read the file at the given path. The user usually passes the path or the issue number.

## Wayfinder operations

`/wayfinder` uses these. The map is one file, and each ticket is its own file.

- The map is `.scratch/<effort>/map.md`, holding the Notes, Decisions so far, and Not yet specified sections.
- A child ticket is `.scratch/<effort>/issues/NN-<slug>.md`, numbered from `01`, with the question in its body. A `Type:` line holds the ticket type (`research`, `prototype`, `grilling`, or `task`). A `Status:` line holds `claimed` or `resolved`.
- A `Blocked by: NN, NN` line near the top records blocking. A ticket is unblocked when every file it lists is `resolved`.
- To find the frontier, scan `.scratch/<effort>/issues/` for files that are not resolved, not claimed, and not blocked. The lowest number is next.
- Claim a ticket by setting `Status: claimed` and saving the file before any other work.
- Resolve a ticket by writing the answer under an `## Answer` heading and setting `Status: resolved`. Then add a line to Decisions so far in `map.md` with a one-line summary and a link.
