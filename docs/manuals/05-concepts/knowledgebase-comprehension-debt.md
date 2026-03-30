> **[EXAMPLE - Magento 2 + React]** This concept doc is from a Magento 2 + React project. It will be deleted when you run `/setup-project`. It serves as an example of the kind of architecture knowledge you should capture for your own project.

# Comprehension debt and AI-assisted development

Comprehension debt is the growing gap between how much code exists in a system and how much of it any human genuinely understands. Unlike technical debt, it accumulates invisibly — the codebase appears healthy (tests pass, linting is clean, types check) while understanding erodes underneath.

This toolchain accelerates code generation significantly. A developer can go from Jira ticket to merged PR using `/plan-feature` → `/implement-feature` → `/commit` without reading a single line of generated code. That's the comprehension debt trap.

## Why AI tooling amplifies the risk

**Speed asymmetry.** AI generates code far faster than humans can evaluate it. The traditional dynamic — senior engineers review faster than juniors write — is inverted. Now anyone can generate full-stack features faster than they can be critically audited.

**Surface correctness.** AI-generated code is syntactically clean, passes type checks, and follows patterns. These are precisely the signals that historically triggered merge confidence. But surface correctness does not indicate systemic correctness — whether the code handles edge cases, respects domain rules, or integrates correctly with the broader system.

**Passive delegation.** Research shows developers who passively delegate to AI score below 40% on comprehension tests, while those who use AI for question-driven exploration score above 65%. The difference is engagement, not capability.

## How this toolchain can cause it

| Step | Passive (debt-accumulating) | Active (debt-avoiding) |
|------|---------------------------|----------------------|
| `/plan-feature` | Approve the plan without reading the reference strategy or novelty assessment | Verify you can explain the data flow end-to-end before approving |
| `/implement-feature` | Read only the change summary, skip the actual files | Read the "key files to understand" list and trace the primary flow yourself |
| Auto review | See "no blockers" and proceed immediately | Read the reviewer's findings and check whether they match your own understanding |
| `/document` | Commit the architecture doc without reading it | Use the doc to verify your mental model matches what was built |
| `/commit` | Reply "go" to the commit plan | Check that the commit grouping matches your understanding of the feature's layers |

## How to use this toolchain actively

### Before planning: build your own mental model first

Before running `/plan-feature`, use `@codebase-qa` to ask questions about the area you're working in. This builds understanding *before* the planner does its research, so you can evaluate the plan critically rather than accepting it on trust.

```
@codebase-qa How does the [reference module] handle [the pattern you need]?
```

### During plan review: verify you can explain the flow

The plan contains a "Reference strategy" and "File plan" section. Before approving, verify that you can answer:

- What data flows from the user through the frontend to the backend?
- Which existing patterns are being reused, and why?
- What are the integration points between layers (data attributes, GraphQL schema, admin config)?

If you can't answer these from the plan alone, use `@codebase-qa` to fill the gaps *before* running the implementer.

### After implementation: read the key files

The implementer's output includes a "Key files to understand" section listing the 3-5 most important files for comprehending the feature. Read these files — not just the change summary. Trace the primary data flow through them:

1. Where does user input enter? (widget entry point or form component)
2. How does it reach the backend? (GQL mutation → resolver)
3. What does the backend do with it? (model, email, database)
4. How does the response get back to the user? (resolver return → provider → component state)

### During documentation review: use it as a comprehension test

When the `/document` skill generates the architecture document, read it as a quiz: does the diagram match your understanding? Can you follow the sequence diagram without surprises? Any mismatch between the doc and your mental model is a comprehension gap to investigate.

## The rule

**Never merge code you cannot explain.** The agents handle the mechanical work — generating patterns, checking syntax, enforcing conventions. The human's job is understanding: why this approach, how the pieces connect, what breaks if assumptions change. That understanding is what makes you capable of debugging, extending, and maintaining the feature after the agents are gone.
