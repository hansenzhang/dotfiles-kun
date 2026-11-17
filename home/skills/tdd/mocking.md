# When to mock

Mock only at system boundaries:

- External APIs, such as payment or email.
- Databases, sometimes. Prefer a test database.
- Time and randomness.
- The file system, sometimes.

Don't mock:

- Your own classes or modules.
- Internal collaborators.
- Anything else you control.

## Designing boundaries that are easy to mock

At a system boundary, design the interface so a test can replace it.

### 1. Pass dependencies in

Pass external dependencies as arguments instead of creating them inside the function:

```typescript
// Easy to mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// Hard to mock
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

### 2. Write one function per external operation

Write a separate function for each external operation instead of one generic function that branches on its arguments:

```typescript
// GOOD: each function can be mocked on its own
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// BAD: the mock needs branching logic
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

With one function per operation:

- Each mock returns one shape.
- Test setup has no branching logic.
- You can see which endpoints a test calls.
- Each endpoint has its own types.
