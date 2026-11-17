# Good and bad tests

## Good tests

A good test goes through real interfaces and doesn't mock internal parts.

```typescript
// GOOD: tests behavior a caller can observe
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

A good test:

- Tests behavior that users or callers care about.
- Uses only the public API.
- Still passes after an internal refactor.
- Has a name that says what happens, not how.
- Makes one logical assertion.

## Bad tests

A test of implementation details depends on the code's internal structure.

```typescript
// BAD: tests implementation details
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

Signs of a bad test:

- It mocks internal collaborators.
- It tests private methods.
- It asserts on how many times, or in what order, functions were called.
- It breaks during a refactor that doesn't change behavior.
- Its name says how the code works instead of what it does.
- It checks the result some other way than through the interface.

```typescript
// BAD: goes around the interface to check the result
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// GOOD: checks the result through the interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

A tautological test computes its expected value the way the code does, so it passes by construction.

```typescript
// BAD: computes the expected value the same way the code does
test("calculateTotal sums line items", () => {
  const items = [{ price: 10 }, { price: 5 }];
  const expected = items.reduce((sum, i) => sum + i.price, 0);
  expect(calculateTotal(items)).toBe(expected);
});

// GOOD: the expected value is a known literal
test("calculateTotal sums line items", () => {
  expect(calculateTotal([{ price: 10 }, { price: 5 }])).toBe(15);
});
```
