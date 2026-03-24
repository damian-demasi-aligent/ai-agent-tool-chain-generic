> **[EXAMPLE - Magento 2 + React]** This concept doc is from a Magento 2 + React project. It will be deleted when you run `/setup-project`. It serves as an example of the kind of architecture knowledge you should capture for your own project.

# Apollo Client caching behaviour

The project uses Apollo Client with its default `cache-first` fetch policy. This has practical implications:

- **Queries are cached after the first response.** Subsequent calls to the same query (same variables) return the cached result without hitting the server.
- **Mutations always hit the server** but do not automatically update cached queries.
- **Admin-configurable data** (like hire categories or funding options) will not refresh during a user's session unless the component explicitly uses `cache-and-network` or `network-only`.

For data that admins change infrequently, `cache-first` is acceptable — the user gets a fast experience and changes appear on next page load. For data that must always be current (cart, stock availability), use `network-only` or `cache-and-network`.
