# Glossary format

The glossary lives at `docs/glossary.md`.

## Structure

```md
# {Context name}

{One or two sentences on what this context covers and why it exists.}

## Language

**Order**:
{One or two sentences defining the term}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account
```

## Rules

- Pick one word per concept. When several words name the same concept, choose the best one and list the others under `_Avoid_`.
- Keep each definition to one or two sentences. Say what the thing is, not what it does.
- Include only terms specific to this project. General programming concepts such as timeouts, error types, and utility patterns stay out, even when the project uses them heavily. Before adding a term, ask whether it is unique to this context. Add it only if it is.
- Group terms under subheadings when they fall into clusters. If every term belongs to one area, a flat list is fine.

## Single and multi-context repos

Most repos have a single context, with one glossary at `docs/glossary.md`.

A repo with several contexts has a `docs/glossary-map.md`. It lists each context, where its glossary lives, and how the contexts relate:

```md
# Glossary map

## Contexts

- [Ordering](../src/ordering/docs/glossary.md): receives and tracks customer orders
- [Billing](../src/billing/docs/glossary.md): generates invoices and processes payments
- [Fulfillment](../src/fulfillment/docs/glossary.md): manages warehouse picking and shipping

## Relationships

- Ordering to Fulfillment. Ordering emits `OrderPlaced` events, and Fulfillment consumes them to start picking.
- Fulfillment to Billing. Fulfillment emits `ShipmentDispatched` events, and Billing consumes them to generate invoices.
- Ordering and Billing share the `CustomerId` and `Money` types.
```

Decide which structure applies:

- If `docs/glossary-map.md` exists, read it to find the contexts.
- If only `docs/glossary.md` exists, the repo has one context.
- If neither exists, create `docs/glossary.md` when the first term is resolved.

With several contexts, work out which one the current topic belongs to. If you can't tell, ask.
