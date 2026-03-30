---
name: document
description: Generate a feature architecture document for a completed feature. Creates Mermaid diagrams, data flows, deployment steps, and captures screenshots via Playwright when available. Use after implementing a feature.
argument-hint: "Ticket number (e.g., PROJ-700), ticket + feature name, or branch name"
disable-model-invocation: true
---

# Document Feature

Generate architecture documentation for "$ARGUMENTS".

If $ARGUMENTS is empty, the agent will infer the ticket from the current branch name. If this is not possible, use the AskUserQuestion tool to ask the user which feature to document.

Use the **Agent tool** to spawn the `documenter` agent:

```
Agent tool call:
  description: "Document feature"
  subagent_type: "documenter"
  prompt: "$ARGUMENTS"
```

Wait for the agent to complete, then present its results to the user. The agent will:

1. Read the code on the current branch and trace the architecture
2. Write a feature document to `docs/features/`
3. Capture screenshots via Playwright (when the dev server is available)
4. Analyse the implementation for lessons learned and propose additions to `CLAUDE.md` or `.claude/rules/`
5. Report the file path, sections included, TODO items, and proposed lessons

After the document is generated, remind the user to commit it using `/commit`.
