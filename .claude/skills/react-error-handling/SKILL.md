---
name: react-error-handling
description: Error handling patterns for React components. Use when writing API calls, form validation with Zod, or error display in components.
user-invocable: false
metadata:
  capabilities: [react]
---

# React Error Handling Patterns

Follow these patterns at each layer for consistent error handling. Before starting, **read CLAUDE.md** for the project's Architecture section, and the project rules (`.claude/rules/react-conventions.md`) for the specific error return type, error constants location, and error display conventions.

## API / Provider Layer

Check the project rules (`.claude/rules/react-conventions.md`) for the project's API return type convention (e.g. a discriminated union like `ActionResult<T>`). The general pattern:

```typescript
async submitSomething(data: InputType): Promise<Result<ResponseType>> {
    try {
        const { data: result } = await this.provider.doSomething(data);
        if (!result.expected_field) {
            return { status: 'error', message: 'Something went wrong...' };
        }
        return { status: 'success', payload: result };
    } catch (error) {
        return {
            status: 'error',
            message: error instanceof Error ? error.message : 'An unexpected error occurred.',
        };
    }
}
```

**Never throw from provider methods** — always return the project's result type so consumers can handle errors without try/catch.

## REST / Fetch Calls

For non-GraphQL fetch calls, use try/catch and report errors through the project's error constant system (check the project rules in `.claude/rules/react-conventions.md` for the constants location and shape):

```typescript
try {
  const response = await fetch(url, { signal });
  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }
  return await response.json();
} catch {
  handleError(ERROR_MESSAGES.fetchErrorSomething);
  return defaultValue;
}
```

## Context-Level Error State

For features with multiple possible concurrent errors, use an error array in context with deduplication and targeted removal:

```typescript
const [errors, setErrors] = useState<ErrorMessage[]>([]);

const handleError = (error: ErrorMessage, action?: 'remove') => {
  setErrors(prev => {
    if (action === 'remove') return prev.filter(e => e.message !== error.message);
    if (prev.some(e => e.message === error.message)) return prev;
    return [...prev, error];
  });
};
```

This deduplicates errors by message and supports targeted removal.

## Form Validation (Zod)

Use Zod schemas with `safeParse` — never `parse` (which throws):

```typescript
const result = schema.safeParse(formData);
if (!result.success) {
  const validationErrors: Record<string, string> = {};
  for (const error of result.error.errors) {
    if (error.path[0] !== undefined) {
      validationErrors[error.path[0]] = error.message;
    }
  }
  setErrors(validationErrors);
  return; // Early return, don't proceed
}
onNext(formData);
```

## Error Display

**Check the project rules** (`.claude/rules/react-conventions.md`) for the project's error styling constants and conventions. Always show both an icon and text — never rely on colour alone (see the react-a11y-check skill for full accessibility rules).
