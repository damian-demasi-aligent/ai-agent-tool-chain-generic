> **[EXAMPLE - Magento 2 + React]** This concept doc is from a Magento 2 + React project. It will be deleted when you run `/setup-project`. It serves as an example of the kind of architecture knowledge you should capture for your own project.

# Magento extension mechanisms: plugins vs observers

Magento provides two primary ways to extend core behaviour without modifying vendor code. Choosing the wrong one causes subtle bugs or tight coupling.

### Plugins (Interceptors)

Plugins intercept **specific method calls** on a class. You get the full method signature — arguments in, result out — and can modify either.

```
before[Method]  → modify arguments before the method runs
after[Method]   → modify the return value after the method runs
around[Method]  → wrap the method entirely (call $proceed when ready)
```

**When to use:** You need to change the behaviour of a specific method — modify its input, alter its return value, or conditionally skip it.

**Project convention (check CLAUDE.md):** Prefer `before`/`after` over `around`. An `around` plugin that forgets to call `$proceed()` silently breaks the entire method chain. The `/plugin` command enforces this.

**Registered in:** `etc/di.xml` (global), `etc/frontend/di.xml` (frontend-only), or `etc/adminhtml/di.xml` (admin-only).

### Observers

Observers listen to **events dispatched by the framework**. They are loosely coupled — you can only react to data the dispatcher chose to expose via `$observer->getEvent()->getData()`.

**When to use:** You need to react to something happening (order placed, product saved, page rendered) without changing the operation itself.

**Key limitation:** You cannot modify the return value of the operation that dispatched the event. If you need to change behaviour, use a plugin. If you need to react to behaviour, use an observer.

**Registered in:** `etc/events.xml` (global), `etc/frontend/events.xml` (frontend-only), or `etc/adminhtml/events.xml` (admin-only). Always use the narrowest scope.

**Project convention (check CLAUDE.md):** Observer names in `events.xml` use `snake_case` with the project's prefix (e.g. `<prefix>_sales_model_service_quote_submit_before`). The `/observer` command follows existing project examples.

### Decision guide

| Need | Mechanism | Example |
|---|---|---|
| Modify a method's arguments | `before` plugin | Change product price before save |
| Modify a method's return value | `after` plugin | Add custom data to API response |
| Replace method logic entirely | `around` plugin (use sparingly) | Skip shipping calculation conditionally |
| React to an event (no return modification) | Observer | Send email after order is placed |
| Add data to a block/template context | `after` plugin on Block method, or ViewModel | Inject extra data for rendering |
