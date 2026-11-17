# Deepening

How to merge a group of shallow modules into a deep one safely, given their dependencies. This file uses the terms module, interface, seam, and adapter from [SKILL.md](SKILL.md).

## Dependency categories

When you assess a candidate for deepening, sort its dependencies into the categories below. The category decides how you test the deepened module across its seam.

### 1. In-process

Pure computation and in-memory state, with no I/O. These can always be deepened. Merge the modules and test through the new interface directly. No adapter is needed.

### 2. Local stand-in

Dependencies with a local stand-in for tests, such as PGLite for Postgres or an in-memory file system. These can be deepened if the stand-in exists. The test suite runs the deepened module against the stand-in. The seam stays internal, and the module's external interface has no port.

### 3. Remote and owned (ports and adapters)

Your own services across a network, such as microservices or internal APIs. Define a **port**, an interface at the seam. The deep module holds the logic, and the transport is passed in as an adapter. Tests use an in-memory adapter, and production uses an HTTP, gRPC, or queue adapter.

Phrase the recommendation like this: "Define a port at the seam, with an HTTP adapter for production and an in-memory adapter for tests, so the logic lives in one deep module even though it is deployed across a network."

### 4. Third-party (mock)

Services you don't control, such as Stripe or Twilio. The deepened module receives the external dependency as a port, and tests pass a mock adapter.

## Rules for seams

- A seam needs two adapters. Don't add a port unless at least two adapters justify it, usually one for production and one for tests. A seam with one adapter only adds indirection.
- Keep internal seams internal. A deep module can have seams private to its implementation, used by its own tests, as well as the external seam at its interface. Don't expose an internal seam through the interface just because tests use it.

## Testing: replace old tests, don't add layers

- Once tests exist at the deepened module's interface, the old unit tests on the shallow modules have no value. Delete them.
- Write the new tests at the deepened module's interface, since tests use the interface.
- Assert on outcomes you can observe through the interface, not on internal state.
- Tests describe behavior, not implementation, so they should pass after an internal refactor. A test that must change when the implementation changes is testing behind the interface.
