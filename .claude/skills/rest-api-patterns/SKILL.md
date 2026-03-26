---
name: rest-api-patterns
description: Magento 2 REST API patterns. Use when creating or modifying REST endpoints, webapi.xml routes, service contract interfaces, Data interfaces, or their implementations.
user-invocable: false
metadata:
  capabilities: [magento]
---

# Magento 2 REST API Patterns

This skill covers Magento's Web API framework for custom REST endpoints. Before starting, **read CLAUDE.md** for the project's vendor namespace, and the project rules (`.claude/rules/magento-conventions.md`) for REST vs GraphQL boundary rules and reference implementations for existing REST endpoints.

## File Structure

Every REST endpoint requires these files:

| File | Purpose |
|---|---|
| `etc/webapi.xml` | Declares the route URL, HTTP method, service class, and access control |
| `Api/<Name>Interface.php` | Service contract interface — the public API surface |
| `Api/Data/<Name>Interface.php` | Data transfer object interface (for request bodies or structured responses) |
| `Model/<Name>.php` | Implementation of the service contract |
| `Model/<Data>.php` | Implementation of the Data interface (when a DTO is needed) |
| `etc/di.xml` | `<preference>` mappings from interfaces to implementations |

## webapi.xml

Routes are declared under `etc/webapi.xml`:

```xml
<?xml version="1.0"?>
<routes xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Webapi:etc/webapi.xsd">
    <route url="/V1/<resource-path>" method="GET|POST|PUT|DELETE">
        <service class="<Vendor>\<Module>\Api\<Name>Interface" method="<methodName>"/>
        <resources>
            <resource ref="self"/>         <!-- authenticated as current customer -->
            <!-- OR -->
            <resource ref="anonymous"/>    <!-- publicly accessible, no auth required -->
            <!-- OR -->
            <resource ref="Magento_Backend::admin"/> <!-- admin-only -->
        </resources>
        <!-- Optional: inject request-derived values as forced parameters -->
        <data>
            <parameter name="cartId" force="true">%cart_id%</parameter>
        </data>
    </route>
</routes>
```

**Access control:**
- `anonymous` — publicly accessible (no authentication). Use for read-only public data.
- `self` — authenticated as the current logged-in customer. The framework automatically resolves `%cart_id%` and similar tokens from the session.
- Named ACL resource — restricts to specific admin roles.

**URL versioning:** Always use `/V1/` prefix. Use existing Magento URL namespaces where appropriate (e.g. `/V1/inventory/`, `/V1/carts/`).

## Service Contract Interface (`Api/`)

The interface is the public contract. Its docblock PHPDoc is parsed by the framework to auto-generate REST input/output handling — accuracy is critical.

```php
<?php
declare(strict_types=1);

namespace <Vendor>\<Module>\Api;

use <Vendor>\<Module>\Api\Data\<Request>Interface;
use <Vendor>\<Module>\Api\Data\<Response>Interface;
use Magento\Framework\Exception\LocalizedException;

/**
 * @api
 */
interface <Name>Interface
{
    /**
     * Description of what this endpoint does.
     *
     * @param <Request>Interface $requestData
     * @return <Response>Interface
     * @throws LocalizedException
     */
    public function execute(<Request>Interface $requestData): <Response>Interface;
}
```

**Rules:**
- Always add `@api` docblock tag — marks this as a stable public API
- Parameter and return types in docblocks must use fully-qualified class names when the framework needs to resolve them for serialisation
- Use `@throws` to document exceptions the caller must handle
- Check the project rules (`.claude/rules/magento-conventions.md`) for the project's convention on methods per interface (typically one method per endpoint)

## Data Interface (`Api/Data/`)

DTOs represent structured request bodies or rich response objects.

```php
<?php
declare(strict_types=1);

namespace <Vendor>\<Module>\Api\Data;

interface <Name>Interface
{
    public const FIELD_NAME = 'field_name';

    /**
     * @return string|null
     */
    public function getFieldName(): ?string;

    /**
     * @param string|null $fieldName
     * @return void
     */
    public function setFieldName(?string $fieldName): void;
}
```

**When to create a Data interface:**
- Request body with multiple fields → always
- Simple scalar response (string, bool, int) → skip — return the scalar directly from the service interface
- Rich response object → always

**Getter/setter naming:** Follow Magento convention: `getFoo()` / `setFoo($foo)`. Constants hold field names (used by `db_schema.xml` and `ExtensionAttributes`).

## Implementation (`Model/`)

```php
<?php
declare(strict_types=1);

namespace <Vendor>\<Module>\Model;

use <Vendor>\<Module>\Api\<Name>Interface;
use Magento\Framework\Exception\LocalizedException;
use Psr\Log\LoggerInterface;

class <Name> implements <Name>Interface
{
    public function __construct(
        private readonly LoggerInterface $logger,
        // ... other dependencies
    ) {}

    /**
     * @inheritdoc
     */
    public function execute(...): ...
    {
        try {
            // implementation
        } catch (\Exception $e) {
            $this->logger->critical($e);
            throw new LocalizedException(__('A descriptive user-facing error message.'));
        }
    }
}
```

**Error handling:**
- Wrap all external calls in try/catch
- Log at `critical` level using `LoggerInterface`
- Re-throw as `LocalizedException` with a translated user-facing message — never expose internal exception messages to API consumers
- Use `InputException` for validation failures (malformed input), `LocalizedException` for business logic failures

## di.xml Preferences

Every interface → implementation pair must be declared:

```xml
<preference for="<Vendor>\<Module>\Api\<Name>Interface"
            type="<Vendor>\<Module>\Model\<Name>" />

<preference for="<Vendor>\<Module>\Api\Data\<Data>Interface"
            type="<Vendor>\<Module>\Model\<Data>" />
```

## Common REST Endpoint Patterns

### Pattern A — Authenticated POST with request body

Used when the endpoint modifies customer-owned data and receives a structured payload.

| Aspect | Detail |
|---|---|
| Auth | `<resource ref="self"/>` |
| Forced param | `%cart_id%` injected from session |
| Request body | Custom DTO interface |
| Return | `void` or response DTO |
| Exception type | `InputException` for failures |

The `force="true"` parameter injection pattern lets Magento resolve session-scoped values (cart ID, customer ID) without the client sending them — they cannot be spoofed.

### Pattern B — Anonymous GET with query parameters

Used for public read-only data where no authentication is required.

| Aspect | Detail |
|---|---|
| Auth | `<resource ref="anonymous"/>` |
| Input | Query string parameters resolved via search request interface |
| Return | Custom search result DTO |
| Exception type | `LocalizedException` for failures |

For anonymous endpoints, be careful about performance — results should be cacheable where possible, and expensive queries should have appropriate guards.

## When to Use REST vs GraphQL

**Check the project rules** (`.claude/rules/magento-conventions.md`) for the project's boundary between REST and GraphQL. A common convention: REST is for external/B2B integrations and Magento service extensions, while GraphQL is for frontend widget data fetching. Read the project's existing REST implementations listed in the Reuse Before Reimplementing table in `.claude/rules/` before deciding which pattern to follow.
