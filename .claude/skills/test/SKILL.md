---
name: test
description: Run the project's test suite and report results. Accepts a component name, file path, "changed" for changed files only, or no argument for the full suite. If test infrastructure is not set up, guides you through bootstrapping it first.
argument-hint: 'Optional: component name, file path, or "changed" for changed files only'
disable-model-invocation: true
---

# Run Tests

Run the project's test suite for "$ARGUMENTS".

Use the **Agent tool** to spawn the `test-runner` agent:

```
Agent tool call:
  description: "Run tests"
  subagent_type: "test-runner"
  prompt: "$ARGUMENTS"
```

Wait for the agent to complete, then present its results to the user exactly as returned — do not summarise or filter the output.
