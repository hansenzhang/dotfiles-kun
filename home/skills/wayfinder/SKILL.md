---
name: wayfinder
description: Plan a piece of work too large for one agent session as a map of decision tickets on the issue tracker, and resolve the tickets one at a time until nothing is left to decide before the work can start.
disable-model-invocation: true
---

Use this skill when a loose idea is too big for one agent session and the steps from here to the **destination** aren't known yet. The goal is to find those steps, not to start building. The skill records the plan as a **map** on the repo's issue tracker, then resolves its **decision tickets** one at a time until the route is clear. A decision ticket is a question whose answer is a decision. It is not a slice of the build.

Each effort has its own destination, and naming it comes first because it shapes every ticket. The destination might be a spec to hand off and refine, a decision to lock in before planning starts, or a change made in place, such as a data migration. The map works for any kind of effort, including engineering work and course content.

## Plan, don't build

By default this skill only plans. Each ticket resolves a decision. The map is finished when nothing is left to decide before someone does the work. If you feel pulled to start doing the work, you have usually reached the end of the map, and it is time to hand off. An effort can override this in its Notes section and include execution in the map. Without that, produce decisions, not deliverables.

## Refer to tickets by title

Every map and ticket is an issue, so it has a title. In anything the human reads, such as your messages or the map's Decisions so far, refer to a ticket by its title, never by a bare id, number, or slug. A list like `#42, #43, #44` is unreadable, and titles can be read at a glance. Keep the id and URL as the link on the title.

## The map

The map is one issue on the repo's issue tracker, labelled `wayfinder:map`. Its tickets are child issues of the map.

The map is an index. It lists the decisions made and links to the tickets that hold their detail. Each decision lives in one place, its ticket, so the map never repeats a decision. It gives a one-line summary and a link.

How the map, its child tickets, blocking links, and frontier queries are stored depends on the tracker. The tracker should already be in your context. If it isn't, tell the user to run `/setup-matt-pocock-skills`. Read the "Wayfinder operations" section of the tracker doc to see how this repo does each one. If no tracker is configured, use the local markdown tracker.

### The map body

The map body gives the whole plan in brief, and a session loads it once. Open tickets are not listed in it, because a query finds them as open child issues.

```markdown
## Destination

<What the end of this map looks like: the spec, decision, or change this effort is working toward, in one or two lines. Every session reads it before choosing a ticket.>

## Notes

<The domain, skills every session should load, and standing preferences for this effort.>

## Decisions so far

<!-- The index: one line per closed ticket, with enough to judge whether it matters, and a link to the ticket for the detail. -->

- [<closed ticket title>](link): <one-line summary of the answer>

## Not yet specified

<!-- See "Not yet specified work": in-scope questions too vague to ticket yet. -->

## Out of scope

<!-- See "Out of scope": work ruled outside the destination. These never become tickets. -->
```

### Tickets

Each ticket is a child issue of the map, and the tracker's issue id identifies it. Its body is the question, sized to fit one agent session of about 100K tokens:

```markdown
## Question

<The decision or investigation this ticket resolves.>
```

Each ticket has one `wayfinder:<type>` label, where the type is `research`, `prototype`, `grilling`, or `task` (see [Ticket types](#ticket-types)). The map and its tickets carry only `wayfinder:` labels, never a triage label like `ready-for-agent`, because they are decisions, not implementation work.

A session claims a ticket by assigning it to the developer driving the map. It does this first, before any other work, so that other sessions running at the same time skip it. An open ticket with no assignee is unclaimed.

Record blocking with the tracker's native dependency links. The tracker's UI then shows which tickets can be taken, without anyone opening the map. Fall back to a convention in the ticket body only on a tracker without native blocking. A ticket is **unblocked** when every ticket blocking it is closed. The **frontier** is the set of open child tickets that are unblocked and unclaimed.

The answer is not part of the ticket body. It is recorded when the ticket is resolved (see [Work through the map](#work-through-the-map)). Link any files created while resolving a ticket from the issue instead of pasting them in.

## Ticket types

Every ticket is either human-in-the-loop (HITL), worked through with a human who answers for themselves, or AFK, done by the agent alone. A HITL ticket resolves only through that live exchange. The agent never answers the human's side. A grilling agent that answers its own questions has broken this rule.

- **Research** (AFK). Read documentation, third-party APIs, or local sources such as knowledge bases to find a fact that a decision depends on. A subagent resolves it by calling the Skill tool with "research". Use it when the answer depends on information outside the current working directory.
- **Prototype** (HITL). Build something cheap and rough to react to, such as an outline, a draft, a stub, or UI or logic code, by calling the Skill tool with "prototype". Link the prototype from the ticket. Use it when the main question is how something should look or behave.
- **Grilling** (HITL). A conversation, and the default type. Always call the Skill tool twice, for "grilling" and "domain-modeling".
- **Task** (HITL or AFK). Manual work that must happen before a decision can be made, when there is nothing to decide, prototype, or research yet, but the discussion can't go on until it is done. Examples are signing up for a service so its API can be judged, getting access to something, or moving data so its shape can be seen. This is the only type that does work instead of deciding, and it belongs on the map only because it unblocks a decision. The agent does it alone where it can (AFK). Otherwise it gives the human a precise checklist (HITL). The ticket is resolved when the work is done. Its answer records what was done and any facts later tickets need, such as where credentials live, new URLs, or row counts.

## Not yet specified work

The map is incomplete on purpose. Don't create tickets for questions you can't state yet. Some decisions are clearly coming but depend on questions still open, so they can't be pinned down. Each resolved ticket makes some of them clear enough to become new tickets, until the route to the destination is clear and no tickets remain.

The map's Not yet specified section lists these coming questions: the suspected question, or the area to come back to. Everything in it is in scope but not yet precise enough to ticket. Write as much or as little as you can see. The section also tells collaborators where the effort is heading.

To decide between a ticket and a Not yet specified entry, ask whether you can state the question precisely now. Whether you can answer it now doesn't matter.

- Make a ticket when the question is already precise, even if it is blocked.
- Add a Not yet specified entry when you can't state the question precisely yet. Don't split these entries into ticket-sized pieces in advance. An entry is coarser than a ticket, and it may become several tickets, or none, once the frontier reaches it.

Not yet specified excludes anything already decided (in Decisions so far), anything that is already an open ticket, and anything out of scope (next section).

## Out of scope

The destination sets the scope, so work beyond the destination is out of scope. Out-of-scope work does not go in Not yet specified. It gets its own Out of scope section on the map, which lists work you have deliberately excluded from this effort. Work lands there because of scope, not because it is vague.

Out-of-scope work never becomes a ticket. It returns only if someone changes the destination, and then as a new effort, not a continuation of this one.

Ruling something out of scope sets the scope. It is not a step toward the destination. When an existing ticket turns out to lie beyond the destination, either because it was included by mistake or because a resolution showed it, close it, so it is no longer on the frontier. Add one line to the Out of scope section with a summary, the reason, and a link to the closed ticket. Don't add it to Decisions so far, which records only the steps actually taken.

## Invocation

There are two modes. In either mode, never resolve more than one ticket per session, except for research tickets.

### Create the map

The user invokes the skill with a loose idea.

1. **Name the destination.** Call the Skill tool twice, for "grilling" and "domain-modeling", to settle what the map is working toward: a spec, a decision, or a change. The destination sets the scope, so settle it first.
2. **Find the frontier.** Grill again, broadly this time. Cover the whole problem instead of going deep on one thread, and find the open decisions and the first steps that can be taken now. If this finds nothing unclear, so the route is already clear and the whole job fits in one session, you don't need a map. Stop and ask the user how they want to proceed.
3. **Create the map** with the `wayfinder:map` label. Fill in Destination and Notes, leave Decisions so far empty, and list the questions you can't state yet under Not yet specified.
4. **Create the tickets you can state now** as child issues of the map. Then add blocking links in a second pass, because issues need ids before they can reference each other. Write cross-references in that same pass, using real ids, because a placeholder like `#<n>` links to an unrelated issue. The blocking links sort the tickets into the frontier and the blocked ones. Everything you can't state yet stays in Not yet specified.
5. **Start the research subagents.** For each `research` ticket you created, start a subagent with a fresh context that calls the Skill tool with "research", so they run in parallel. Each one writes its findings to a throwaway `research/<name>` branch and links the branch from its ticket. Push the branch but don't open a PR. It is never merged.
6. **Stop.** Creating the map takes one session, and that session resolves no tickets by hand.

### Work through the map

The user invokes the skill with a map URL or number. Naming a ticket is optional. If the user doesn't name one, you pick the next one.

1. Load the map body. Don't load every ticket body.
2. Choose the ticket. If the user named one, use it. Otherwise take the first frontier ticket in map order. Claim it by assigning it to yourself before any other work.
3. Resolve it according to its `wayfinder:<type>` label (see [Ticket types](#ticket-types)). Read the label, because the body never states the type. Fetch the full body of any related or closed ticket when you need it. Call the Skill tool for each skill the Notes section names. If you are unsure what to do, call the Skill tool twice, for "grilling" and "domain-modeling".
4. Record the resolution. Post the answer as a comment on the ticket, close it, and add a line to the map's Decisions so far with a one-line summary and a link.
5. Create tickets for any new questions the answer raised, then add their blocking links. Move each Not yet specified entry that the answer made precise into a new ticket, and remove it from Not yet specified so it lives only in the ticket. If the answer shows that a ticket, this one or another, lies beyond the destination, rule it out of scope instead of resolving it. If the decision makes other parts of the map wrong, update or delete those tickets.

The user may run unblocked tickets in parallel, so expect other sessions to edit the tracker at the same time.
