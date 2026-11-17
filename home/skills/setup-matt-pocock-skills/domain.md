# Domain docs

How the engineering skills read this repo's domain docs when they explore the codebase.

## Read these before exploring

- `docs/glossary.md`. If `docs/glossary-map.md` exists instead, it lists one glossary per context, so read each one that bears on the topic.
- The ADRs in `docs/adr/` that touch the area you are about to work in. In a repo with several contexts, also check `src/<context>/docs/adr/` for decisions that apply to one context.

If any of these files don't exist, carry on without them. Don't point out that they are missing, and don't suggest creating them in advance. The `/domain-modeling` skill, which `/grill-with-docs` and `/improve-codebase-architecture` call, creates them when a term or decision is actually settled.

## File structure

A single-context repo, which is most repos:

```
/
├── docs/
│   ├── glossary.md
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

A multi-context repo, which has a `docs/glossary-map.md`:

```
/
├── docs/
│   ├── glossary-map.md
│   └── adr/                           <- system-wide decisions
└── src/
    ├── ordering/
    │   └── docs/
    │       ├── glossary.md
    │       └── adr/                   <- decisions for this context
    └── billing/
        └── docs/
            ├── glossary.md
            └── adr/
```

## Use the glossary's terms

When your output names a domain concept, for example in an issue title, a refactor proposal, a hypothesis, or a test name, use the term that the glossary defines. Don't switch to a synonym the glossary lists under `_Avoid_`.

If the concept you need isn't in the glossary, either you are inventing a term the project doesn't use, so reconsider it, or the glossary has a real gap, so note it for `/domain-modeling`.

## Call out conflicts with ADRs

If your output contradicts an existing ADR, say so explicitly instead of overriding it silently:

> _Contradicts ADR-0007 (event-sourced orders), but worth reopening because..._
