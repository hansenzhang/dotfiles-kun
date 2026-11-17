---
name: domain-modeling
description: Build and sharpen a project's domain model. Use when discussing codebase terminology, writing or editing docs/glossary.md, or recording or editing an ADR.
---

# Domain modeling

Build the project's domain model while you design. Challenge terms, invent edge-case scenarios, and write each glossary entry and decision down as soon as it is settled. Reading `docs/glossary.md` for vocabulary doesn't need this skill, because any skill can do that. Use this skill when you are changing the model.

## File structure

Most repos have a single context:

```
/
├── docs/
│   ├── glossary.md
│   └── adr/
│       ├── 0001-event-sourced-orders.md
│       └── 0002-postgres-for-write-model.md
└── src/
```

If a `docs/glossary-map.md` exists, the repo has several contexts, and the map says where each one lives:

```
/
├── docs/
│   ├── glossary-map.md
│   └── adr/                          <- system-wide decisions
├── src/
│   ├── ordering/
│   │   └── docs/
│   │       ├── glossary.md
│   │       └── adr/                  <- decisions for this context
│   └── billing/
│       └── docs/
│           ├── glossary.md
│           └── adr/
```

Create a file only when you have something to put in it. If there is no `docs/glossary.md`, create it when the first term is resolved. If there is no `docs/adr/`, create it when the first ADR is needed.

## During the session

### Check terms against the glossary

When the user uses a term that conflicts with `docs/glossary.md`, say so right away. "Your glossary defines 'cancellation' as X, but you seem to mean Y. Which is it?"

### Replace vague terms

When the user uses a vague or overloaded term, propose one precise term. "You said 'account'. Do you mean the Customer or the User? They are different things."

### Test the model with concrete scenarios

When the discussion turns to how domain concepts relate, test the relationships with specific scenarios. Invent edge cases that force the user to say exactly where one concept ends and the next begins.

### Check claims against the code

When the user says how something works, check whether the code agrees. If it doesn't, say so. "Your code cancels whole Orders, but you just said partial cancellation is possible. Which is right?"

### Update the glossary as terms are resolved

When a term is resolved, update `docs/glossary.md` immediately rather than saving changes for later. Follow [GLOSSARY-FORMAT.md](./GLOSSARY-FORMAT.md).

The glossary holds no implementation details. It is not a spec, a scratch pad, or a place for implementation decisions. It holds definitions of terms and nothing else.

### Offer ADRs rarely

Offer to write an ADR only when all three are true:

1. The decision is hard to reverse, so changing your mind later costs something real.
2. A future reader would be surprised by it and ask why it was done this way.
3. It came from a real trade-off, with real alternatives, and you picked one for specific reasons.

If any of the three is false, skip the ADR. Follow [ADR-FORMAT.md](./ADR-FORMAT.md).
