---
name: tdd
description: Test-driven development. Use when the user wants to build features or fix bugs test-first, mentions "red-green-refactor", or wants integration tests.
---

# Test-driven development

TDD is a loop: write a failing test (red), then make it pass (green). This skill describes how to make that loop produce tests worth keeping: what a good test is, where tests go, which patterns to avoid, and the rules of the loop. Every section applies to every cycle, so check them before and during the loop, not after.

When you explore the codebase, read `docs/glossary.md` if it exists, so test names and interfaces use the project's domain terms. Follow the ADRs in the area you are changing.

## What a good test is

A good test checks behavior through a public interface, not implementation details. The code can be rewritten completely without changing the test. A good test name says what the system can do: "user can checkout with valid cart". The test still passes after a refactor because it doesn't depend on internal structure.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for when to mock.

## Seams

A **seam** is the public boundary where a test observes behavior without reaching inside the code. Tests go at seams and never against internals.

Write tests only at seams the user has agreed to. Before writing any test, list the seams you plan to test and confirm them with the user. Don't write a test at a seam the user hasn't confirmed. You can't test everything, and agreeing on seams first puts the testing effort on the critical paths and the complex logic instead of every edge case.

Ask: "What is the public interface, and which seams should we test?" For each proposed seam, say in one line what it catches and what it misses.

When the interface itself is in question, such as how deep the module is, where the seam belongs, or what the interface exposes, call the Skill tool with "codebase-design". It defines the terms module, interface, depth, seam, adapter, leverage, and locality. Read it as a reference. It doesn't run a session.

## Patterns to avoid

- **Coupled to the implementation.** The test mocks internal collaborators, tests private methods, or checks a result through a side channel, such as querying the database instead of calling the interface. You can tell because the test breaks during a refactor that didn't change behavior.
- **Tautological.** The assertion computes the expected value the same way the code does, for example `expect(add(a, b)).toBe(a + b)`, a snapshot built by hand the same way, or a constant compared with itself. The test passes by construction and can never disagree with the code. Take expected values from an independent source: a known literal, a worked example, or the spec.
- **Horizontal slicing.** You write all the tests first and then all the code. Tests written in bulk check behavior you imagined. They test the shape of the code instead of what the user sees, they don't fail when real behavior changes, and they fix the test structure before you understand the implementation. Work in vertical slices instead: one test, then the code for it, then the next test. Each test is a tracer bullet that uses what the previous cycle taught you.

## Rules of the loop

- Red before green. Write the failing test first, then only enough code to pass it. Don't write code for tests you haven't written yet, and don't add features nobody asked for.
- One slice at a time. Each cycle has one seam, one test, and the smallest implementation that passes.
- Refactor outside the loop. Refactoring happens at review, after the red-green cycles.
