> **[EXAMPLE - Magento 2 + React]** This concept doc is from a Magento 2 + React project. It will be deleted when you run `/setup-project`. It serves as an example of the kind of architecture knowledge you should capture for your own project.

# The React ↔ Magento data bridge

React widgets live inside Magento's server-rendered pages but have no direct access to PHP variables. Data commonly crosses the boundary in three ways:

### 1. HTML data attributes (static, server-known values)

The `.phtml` template renders a `<div>` with data attributes:

```php
<div data-react-widget="my-widget"
     data-recaptcha-type="<?= $escaper->escapeHtmlAttr($recaptchaType) ?>"
     data-store-url="<?= $escaper->escapeHtmlAttr($storeUrl) ?>">
</div>
```

The React widget reads these on mount via `element.dataset`. Use this for configuration that PHP knows at render time (URLs, feature flags, admin-configured options).

**Important:** Always use `$escaper->escapeHtmlAttr()` for data attributes, not `$escaper->escapeHtml()`. The `escapeHtmlAttr` method handles attribute-context edge cases like embedded quotes. The `react-widget-wiring` skill enforces this.

### 2. GraphQL queries (dynamic, runtime data)

For anything that depends on user interaction or must be fresh, the React component calls the GraphQL provider singleton (see CLAUDE.md → Architecture for the exact access pattern), which wraps an Apollo Client query/mutation to `/graphql`.

```
React component → Provider method → Apollo Client → POST /graphql → PHP Resolver → Model
```

### 3. REST APIs (dynamic, runtime data)

For integrations implemented as Magento Web API endpoints, React can call REST routes (typically under `/rest/<store_code>/V1/...`) using `fetch` or a shared API helper.

```
React component → REST client/fetch → /rest/<store_code>/V1/... → Service contract → Model
```

**When to use which:**

| Data type | Bridge | Example |
|---|---|---|
| Config known at page render | Data attribute | reCAPTCHA type, store URL, hear-about-us options |
| Data that changes per user/session | GraphQL query | Cart contents, customer profile |
| User actions that trigger server logic | GraphQL mutation | Form submission, add to cart |
| Integration built on Magento Web API | REST endpoint | Custom `V1` service routes consumed by React |
| Admin-configured options (rarely change) | Either — data attribute avoids a network request, GraphQL query allows caching | Dropdown options use GraphQL; reCAPTCHA type uses data attribute |
