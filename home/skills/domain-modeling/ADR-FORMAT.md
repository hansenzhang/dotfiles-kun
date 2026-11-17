# ADR format

ADRs live in `docs/adr/` and are numbered in sequence: `0001-slug.md`, `0002-slug.md`, and so on.

Create `docs/adr/` when the first ADR is needed, not before.

## Template

```md
# {Short title of the decision}

Date: {YYYY-MM-DD}

{One to three sentences: the context, the decision, and the reason.}
```

The date is the day the decision was made. Every ADR has one, so a reader can tell how old the decision is. An ADR can otherwise be a single paragraph. Its job is to record that a decision was made and why. Filling out sections adds nothing.

## Optional sections

Add these only when they carry information. Most ADRs need none of them.

- A `Status` frontmatter field (`proposed | accepted | deprecated | superseded by ADR-NNNN`), when a decision may be revisited.
- Considered options, when the rejected alternatives are worth remembering.
- Consequences, when a downstream effect is not obvious.

## Numbering

Find the highest number in `docs/adr/` and add one.

## When to offer an ADR

Offer one only when all three of these hold:

1. The decision is hard to reverse, so changing your mind later costs something real.
2. A future reader would be surprised by it and ask why it was done this way.
3. It came from a real trade-off, with real alternatives, and you picked one for specific reasons.

If a decision is easy to reverse, skip the ADR, because you can just reverse it. If it is unsurprising, nobody will ask why. If there was no real alternative, the ADR would only say "we did the obvious thing."

### Decisions that qualify

- The shape of the architecture. "We use a monorepo." "The write model is event-sourced, and the read model is projected into Postgres."
- How contexts talk to each other. "Ordering and Billing communicate through domain events, not synchronous HTTP."
- Technology choices with lock-in, such as the database, message bus, auth provider, or deployment target. This means the choices that would take a quarter to swap out, not every library.
- Boundaries and scope. "The Customer context owns customer data. Other contexts reference it by ID only." Recording what you ruled out matters as much as recording what you chose.
- Deliberate deviations from the obvious path. "We write SQL by hand instead of using an ORM because X." Record anything where a reasonable reader would assume the opposite, so the next engineer doesn't "fix" it.
- Constraints the code can't show. "We can't use AWS because of compliance requirements." "Responses must take under 200ms because the partner API contract requires it."
- Rejected alternatives, when the reason for rejecting them is not obvious. If you picked REST over GraphQL for subtle reasons, record them, or someone will propose GraphQL again in six months.
