---
name: setup-matt-pocock-skills
description: "Configure this repo for the engineering skills: set up its issue tracker, triage label vocabulary, and domain doc layout. Run once before first use of the other engineering skills."
disable-model-invocation: true
---

# Set up the engineering skills

Write the per-repo configuration that the engineering skills read:

- The issue tracker, which is where issues live. GitHub is the default, and local markdown files also work.
- The triage labels, which are the label strings for the five triage roles.
- The domain docs, which are where the glossary and the ADRs live and how skills should read them.

Follow the process below with judgment rather than as a script. Explore, show the user what you found, confirm, and then write.

## Process

### 1. Explore

Read what the repo already has instead of assuming:

- `git remote -v` and `.git/config`, to see whether this is a GitHub repo and which one.
- `AGENTS.md` and `CLAUDE.md` at the repo root, and whether either already has an `## Agent skills` section.
- `docs/glossary.md` and `docs/glossary-map.md`, and the older names `GLOSSARY.md`, `GLOSSARY-MAP.md`, `CONTEXT.md`, and `CONTEXT-MAP.md` at the repo root. If an older name exists, offer to `git mv` it to `docs/glossary.md` or `docs/glossary-map.md`.
- `docs/adr/` and any `src/*/docs/adr/` directories.
- `docs/agents/`, which holds this skill's output from an earlier run.
- `.scratch/`, which means the repo already tracks issues as local markdown files.
- Whether the `triage` skill is installed, either as a `triage` folder next to this one or as `triage` in your skill list. If it isn't, skip section B.
- Signs of a monorepo: a `pnpm-workspace.yaml`, a `workspaces` field in `package.json`, or a `packages/*` directory whose packages each have a `src/`. Only large multi-package repos have these. Without them, the repo has a single context, as almost every repo does.

### 2. Present findings and ask

Summarize what exists and what is missing. Then go through the sections in order, one section and one answer at a time.

Open each section with the recommended answer, so the user can accept it in one word. Explain the choice in one line only when the options really differ. Skip a section when exploration already answered it: section B when `triage` isn't installed, and section C when the repo isn't a monorepo.

**Section A. Issue tracker.**

> The issue tracker is where this repo's issues live. The `to-tickets`, `triage`, and `to-spec` skills read and write it, so they need to know whether to call `gh issue create`, write a markdown file under `.scratch/`, or follow some other process you describe. Pick the place where you actually track this repo's work.

These skills were designed for GitHub. If a `git remote` points at GitHub, propose GitHub. If it points at GitLab (`gitlab.com` or a self-hosted GitLab), propose GitLab. Otherwise, or if the user prefers, offer:

- GitHub, with issues in the repo's GitHub Issues, through the `gh` CLI.
- GitLab, with issues in the repo's GitLab Issues, through the [`glab`](https://gitlab.com/gitlab-org/cli) CLI.
- Local markdown, with issues as files under `.scratch/<feature>/` in this repo. This suits solo projects and repos without a remote.
- Other, such as Jira or Linear. Ask the user to describe their process in one paragraph, and record it as prose.

Record the choice in `docs/agents/issue-tracker.md`. The GitHub and GitLab templates have a "PRs as a request surface" setting, which is off by default. Leave it off and don't mention it. A user who wants outside PRs in the triage queue can turn it on in the file later.

A GitHub or GitLab tracker needs a repo you can reach. If the user picks one and no `git remote` points at that host, ask for the repo URL and connect it (`git init` if needed, then `git remote add origin <url>`) before going on. This step is done when `gh repo view` or `glab repo view` prints the project from inside this directory. If it can't, stop and tell the user what is missing.

**Section B. Triage labels.** Skip this section if the `triage` skill isn't installed, because no other skill needs the labels.

If `triage` is installed, ask one question:

> Do you want to keep the default triage labels? (recommended: **yes**)

The defaults are the five roles, each with a label string equal to its name: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. On yes, write them as they are. On no, which usually means the tracker already uses other names (for example `bug:triage` for `needs-triage`), collect the replacements so that `triage` applies the existing labels instead of creating duplicates.

**Section C. Domain docs.** Default to a single context: one `docs/glossary.md` and one `docs/adr/`. This fits almost every repo, so write it without asking.

Offer several contexts, with a `docs/glossary-map.md` pointing to one `src/<context>/docs/glossary.md` per context, only when exploration found monorepo signs. In that case, confirm which layout the user wants.

### 3. Confirm and edit

Show the user drafts of:

- The `## Agent skills` block for `CLAUDE.md` or `AGENTS.md`. Step 4 says which file.
- `docs/agents/issue-tracker.md`, `docs/agents/domain.md`, and, only when `triage` is installed, `docs/agents/triage-labels.md`.

Let the user edit them before you write anything.

### 4. Write

Pick the file to edit:

- If `CLAUDE.md` exists, edit it.
- Otherwise, if `AGENTS.md` exists, edit it.
- If neither exists, ask the user which one to create. Don't pick for them.

Never create `AGENTS.md` when `CLAUDE.md` exists, or the other way round. Edit the one that is already there.

If the chosen file already has an `## Agent skills` block, update that block instead of adding a second one. Leave the user's other sections alone.

The block:

```markdown
## Agent skills

### Issue tracker

[One line on where issues are tracked.] See `docs/agents/issue-tracker.md`.

### Triage labels

[One line on the label names.] See `docs/agents/triage-labels.md`.

### Domain docs

[One line on the layout: single-context or multi-context.] See `docs/agents/domain.md`.
```

Include the `### Triage labels` part, and write `docs/agents/triage-labels.md`, only when `triage` is installed and section B ran. Otherwise leave both out.

When section B ran on GitHub or GitLab, create each configured label that the tracker lacks with `gh label create` or `glab label create`.

Then write the docs files, starting from the templates in this skill's folder:

- [issue-tracker-github.md](./issue-tracker-github.md) for a GitHub tracker.
- [issue-tracker-gitlab.md](./issue-tracker-gitlab.md) for a GitLab tracker.
- [issue-tracker-local.md](./issue-tracker-local.md) for a local markdown tracker.
- [triage-labels.md](./triage-labels.md) for the label mapping, only if `triage` is installed.
- [domain.md](./domain.md) for the domain doc layout and how skills read it.

For an "other" tracker, write `docs/agents/issue-tracker.md` from the user's description.

### 5. Finish

Tell the user that setup is complete and which engineering skills read these files. Tell them they can edit `docs/agents/*.md` directly later. They only need to run this skill again to switch issue trackers or start over.
