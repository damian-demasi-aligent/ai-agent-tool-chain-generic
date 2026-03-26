---
name: plan-feature
description: Orchestrate the full planning workflow for a feature. Runs codebase research, impact analysis, and produces a file-by-file implementation plan. Use when starting work on a new feature, especially multi-layer features that span backend and frontend.
argument-hint: "Path to requirements file (e.g., docs/requirements/ABC-123/description.md)"
disable-model-invocation: true
---

# Plan Feature

Orchestrate the full planning workflow for "$ARGUMENTS".

You coordinate five phases — context gathering, scoping, codebase research, impact analysis, and planning — then report the results. Complete all phases in order.

## Phase 0: Gather context

Run these commands in parallel to establish context:

- `git branch --show-current` — extract the ticket identifier from the branch name
- `ls docs/requirements/` — check available requirements files
- `ls docs/plans/` — check for existing plans (avoid duplicating work)

## Phase 1: Read requirements and identify scope

1. **Read the requirements.** If $ARGUMENTS is a file path (e.g. `docs/requirements/ABC-123/description.md`), read it. If it's a ticket number, look for a matching directory or file in `docs/requirements/`. If it's a description, use it directly.

2. **Read CLAUDE.md** (Architecture section) and the **project rules** (`.claude/rules/`) — specifically the **Reuse Before Reimplementing** table. Identify:
   - Which reference features are the closest analogues
   - Which existing modules/components might be extended vs. new ones needed
   - Which shared files will likely need modification (API providers, types, configuration)

3. **Determine the technical needs** of the feature: does it need an API endpoint/mutation? Transactional emails? Admin config? A frontend form? A new component/page? Map each need to the reference feature from the Reuse Before Reimplementing table in `.claude/rules/`.

## Phase 2: Research via codebase-qa agents

Based on the analogues and technical needs identified in Phase 1, use the **Agent tool** to launch `codebase-qa` agents in parallel. Each agent call must use `subagent_type: "codebase-qa"`.

**Goal: minimise agent count while covering all integration points.** Each agent should cover a broad, coherent domain — not a single narrow question. Aim for **2–3 agents** that together cover the full scope. Only use 4 if the feature genuinely spans unrelated domains (e.g. a frontend widget AND an unrelated backend module AND email AND shipping).

**Anti-pattern to avoid:** Do NOT launch separate agents for topics that share the same files. For example, if two concerns share the same module or component — combine them into one agent that investigates it end-to-end.

**Formulate broad domain questions.** Each question should cover a complete domain area, asking the agent to trace the full flow. Examples (adapt to the actual feature and stack):

- "Investigate the [reference module/component] end-to-end: what data models exist, how is the form/page structured, what hooks/plugins/middleware fire, and what configuration exists?"
- "How does the framework handle [specific flow] — trace from entry point through to data persistence, including what parameters are read and what events are dispatched?"
- "What is the complete API + frontend data flow for [reference feature]? Show schema/endpoint, handler/resolver, client operation, data layer method, types, and component usage."

**How to invoke:** Use the `Agent` tool (NOT "Subagent" — the tool is called `Agent`) like this for each research question:

```
Agent tool call:
  description: "Research [topic]"
  subagent_type: "codebase-qa"
  prompt: "[your broad domain question]"
```

**Guidelines:**

- Launch **2–3 Agent calls** (only 4 if the feature spans truly unrelated domains)
- Each question covers a **complete domain** — not a single file or class
- Ensure no two agents will read the same module or files — if they would, merge them
- Launch ALL Agent calls in a single message for parallel execution
- Wait for all to complete before proceeding

**Record results.** For each agent, note the domain investigated and a one-line summary of the key finding. You'll pass these to the planner.

## Phase 3: Impact analysis via impact-analyser agents

After research completes, decide whether impact analysis is needed. **This phase is expensive — only run it when justified.**

### When to SKIP this phase

Skip impact analysis and note "Impact analysis: skipped" when ANY of these apply:

- The feature is **mostly additive** — primarily new files within one module, with only minor modifications to existing shared files (e.g. adding entries to di.xml, adding a block to layout XML, appending to a types file)
- The feature **extends a single module** without touching cross-module shared interfaces
- The research agents already identified the exact files and changes needed — the feature-planner agent will read those files itself

### When to RUN this phase

Run impact analysis **only** when the feature modifies **high-risk shared infrastructure** that multiple other features depend on:

- Changing the signature or behaviour of existing shared interfaces in `Api/`
- Restructuring the GraphQL provider singleton (not just adding methods — changing existing ones)
- Modifying shared configuration that affects multiple modules
- Replacing or removing existing shared components

If justified, use the **Agent tool** to launch **1–2 `impact-analyser` agents** (not more), one per high-risk shared area:

```
Agent tool call:
  description: "Impact analysis [target]"
  subagent_type: "impact-analyser"
  prompt: "Analyse the impact of [modification] to [file]"
```

**Record results.** For each agent, note the target analysed and a one-line summary of findings.

## Phase 4: Delegate to `feature-planner`

Spawn the `feature-planner` agent via the Agent tool. Do not write the plan yourself — the `feature-planner` has specialized skills (react-patterns, magento-module, email-patterns, etc.) that produce a higher-quality plan.

Include in the prompt:

1. The original requirements (full text or summary)
2. A **Research Findings** section with all codebase-qa results
3. An **Impact Analysis** section with all impact-analyser results (or "skipped" note)
4. Any constraints or scope notes you identified in Phase 1

**Invoke like this:**

```
Agent tool call:
  description: "Plan feature implementation"
  subagent_type: "feature-planner"
  prompt: "[structured prompt as shown below]"
```

Structure the prompt like this:

```
Plan the implementation of the following feature.

## Requirements
[paste or summarise the requirements]

## Research Findings
The following codebase research was conducted by codebase-qa agents:

### Research 1: [question]
[paste the sub-agent's response]

### Research 2: [question]
[paste the sub-agent's response]

[...repeat for each research sub-agent]

## Impact Analysis
The following impact analysis was conducted by impact-analyser agents:

### Impact 1: [target]
[paste the sub-agent's response]

[...repeat for each impact sub-agent, or note "Skipped — all new files"]

## Constraints
[any delivery constraints, scope notes, or decisions from Phase 1]
```

## Phase 5: Report

After the `feature-planner` agent completes, report:

1. The saved plan file path
2. A summary of agent activity:

```
## Agent Activity Report

| # | Agent Type | Question / Target | Key Finding |
|---|---|---|---|
| 1 | codebase-qa | [question] | [one-line summary] |
| 2 | codebase-qa | [question] | [one-line summary] |
| 3 | impact-analyser | [target] | [one-line summary] |
| 4 | feature-planner | [one-line prompt summary] | [one-line summary] |

**Totals:** X codebase-qa agents, Y impact-analyser agents, Z total.
```

3. The number of open questions in the plan
4. A reminder: "Review the plan at [path]. Verify you can explain the feature's data flow end-to-end before running the feature-implementer."
