---
name: codebase-design
description: Shared vocabulary for designing deep modules. Use when the user wants to design or improve a module's interface, find deepening opportunities, decide where a seam goes, make code more testable or easier for agents to navigate, or when another skill needs the deep-module vocabulary.
---

# Codebase design

Design **deep modules**: modules with a lot of behavior behind a small interface, placed at a clear seam, and tested through that interface. Use the terms and principles below whenever you design or restructure code. A deep module gives callers more behavior per thing they learn, keeps changes for maintainers in one place, and lets tests go through one interface.

## Glossary

Use these terms exactly. Don't swap in "component", "service", "API", or "boundary". The terms only help if everyone uses the same ones.

**Module**: anything with an interface and an implementation, at any size: a function, a class, a package, or a slice that spans tiers. _Avoid_: unit, component, service.

**Interface**: everything a caller must know to use the module correctly. That includes the type signature, and also invariants, ordering constraints, error modes, required configuration, and performance characteristics. _Avoid_: API, signature. Both mean only the types.

**Implementation**: the code inside a module. It differs from an adapter. A small adapter can have a large implementation, such as a Postgres repository, and a large adapter can have a small implementation, such as an in-memory fake. Say "adapter" when the discussion is about the seam, and "implementation" otherwise.

**Depth**: how much behavior a caller or test can use per unit of interface it has to learn. A module is **deep** when a lot of behavior sits behind a small interface. It is **shallow** when the interface is nearly as complex as the implementation.

**Seam** (Michael Feathers' term): a place where you can change behavior without editing the code at that place. The seam is where a module's interface lives. Where to put the seam is a separate decision from what goes behind it. _Avoid_: boundary, which DDD already uses for "bounded context".

**Adapter**: a concrete thing that satisfies an interface at a seam. The word names the slot it fills, not what it contains.

**Leverage**: what callers get from depth. Each thing a caller learns about the interface gives it more behavior, and one implementation serves N call sites and M tests.

**Locality**: what maintainers get from depth. Changes, bugs, knowledge, and verification stay in one place instead of spreading across callers, so a fix in that place fixes every caller.

## Deep and shallow modules

A deep module has a small interface and a large implementation:

```
┌─────────────────────┐
│   Small interface   │  <- few methods, simple parameters
├─────────────────────┤
│                     │
│ Large implementation│  <- complex logic hidden from callers
│                     │
└─────────────────────┘
```

A shallow module has a large interface and a small implementation. Avoid it:

```
┌─────────────────────────────────┐
│       Large interface           │  <- many methods, complex parameters
├─────────────────────────────────┤
│  Small implementation           │  <- passes calls through
└─────────────────────────────────┘
```

When you design an interface, ask:

- Can it have fewer methods?
- Can the parameters be simpler?
- Can more complexity move inside?

## Principles

- **Depth belongs to the interface, not the implementation.** A deep module can be built from small parts that are easy to mock and swap, as long as those parts stay out of its interface. A module can have **internal seams**, private to its implementation and used by its own tests, as well as the **external seam** at its interface.
- **The deletion test.** Imagine deleting the module. If the complexity disappears with it, the module only passed calls through. If the complexity reappears in N callers, the module was doing real work.
- **Tests use the interface.** Callers and tests cross the same seam. If you want to test behind the interface, the module probably has the wrong shape.
- **A seam needs two adapters.** With one adapter, the seam is hypothetical. With two, it is real. Don't add a seam unless something actually varies across it.

## Designing for testability

A good interface is easy to test:

1. Accept dependencies instead of creating them.

   ```typescript
   // Testable
   function processOrder(order, paymentGateway) {}

   // Hard to test
   function processOrder(order) {
     const gateway = new StripeGateway();
   }
   ```

2. Return results instead of producing side effects.

   ```typescript
   // Testable
   function calculateDiscount(cart): Discount {}

   // Hard to test
   function applyDiscount(cart): void {
     cart.total -= discount;
   }
   ```

3. Keep the interface small. Fewer methods need fewer tests, and fewer parameters need less test setup.

## How the terms relate

- A module has exactly one interface, which callers and tests both use.
- Depth is a property of a module, measured against its interface.
- A seam is where a module's interface lives.
- An adapter sits at a seam and satisfies the interface.
- Depth gives callers leverage and gives maintainers locality.

## Definitions we rejected

- Depth as the ratio of implementation lines to interface lines (Ousterhout). This rewards padding the implementation. We define depth as leverage instead.
- "Interface" as the TypeScript `interface` keyword or a class's public methods. This is too narrow, because here the interface includes every fact a caller must know.
- "Boundary". DDD already uses it for "bounded context". Say seam or interface.

## Further reading

- [DEEPENING.md](DEEPENING.md) covers how to deepen a group of modules given their dependencies: dependency categories, rules for seams, and replacing old tests instead of adding new layers.
- [DESIGN-IT-TWICE.md](DESIGN-IT-TWICE.md) covers exploring alternative interfaces: parallel subagents each design the interface a very different way, then you compare the designs on depth, locality, and seam placement.
