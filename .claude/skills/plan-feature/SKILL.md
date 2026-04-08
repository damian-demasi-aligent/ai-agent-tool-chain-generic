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

After extracting the ticket identifier, check for `docs/requirements/<TICKET>/session-state.md`. If it exists and its `Workflow` field is `plan-feature`, read it and report: "Found saved session state (last completed: Phase N)." Use the saved data as context for the current run.

## Phase 1: Read requirements and identify scope

1. **Read the requirements.** If $ARGUMENTS is a file path (e.g. `docs/requirements/ABC-123/description.md`), read it. If it's a ticket number, look for a matching directory or file in `docs/requirements/`. If it's a description, use it directly.

2. **Read CLAUDE.md** (Architecture section) and the **project rules** (`.claude/rules/`) — specifically the **Reuse Before Reimplementing** table. Identify:
   - Which reference features are the closest analogues
   - Which existing modules/components might be extended vs. new ones needed
   - Which shared files will likely need modification (API providers, types, configuration)

3. **Determine the technical needs** of the feature: does it need an API endpoint/mutation? Transactional emails? Admin config? A frontend form? A new component/page? Map each need to the reference feature from the Reuse Before Reimplementing table in `.claude/rules/`.

## Phase 1.5: Requirements completeness interview (conditional)

After reading the requirements in Phase 1, assess whether they are detailed enough to produce a high-quality plan. This prevents wasting tokens on codebase research before the scope is clear.

### Assess completeness

Check the requirements text for the presence of these signals:

| # | Signal | Present if the requirements contain... |
|---|--------|----------------------------------------|
| 1 | Acceptance criteria | A section titled "Acceptance Criteria" / "AC", Given/When/Then blocks, or a numbered list of testable success conditions |
| 2 | Specified layers | Explicit mentions of layers: "API", "GraphQL", "REST", "mutation", "component", "widget", "admin config", "email", "database", "migration", "page", "form" |
| 3 | Data model | Named fields, attributes, columns, or entity descriptions (e.g. "name field", "status attribute", "date column", "extends the order entity") |
| 4 | UI interaction model | References to forms, modals, drawers, pages, steps, wizards, listings, OR the presence of mockup files in `docs/requirements/<TICKET>/attachments/` |
| 5 | Error / edge cases | Mentions of "error", "validation", "edge case", "failure", "fallback", "empty state", or specific error scenarios |
| 6 | Integration points | Mentions of third-party services, external APIs, email recipients, webhooks, cron jobs, or references to existing modules/components by name |

**If all signals are present:** Note "Requirements assessment: COMPLETE — skipping interview" and proceed directly to Phase 2.

**If a previous interview supplement exists** at `docs/requirements/<TICKET>/interview-supplement.md`: Read it, present the answers to the user, and use **AskUserQuestion** to confirm: "I found answers from a previous requirements interview. Are these still correct?" with options "Yes, use these answers" / "No, let's redo the interview". If reusing, skip the interview and proceed to Phase 2.

**If signals are missing:** Conduct the interview below, asking only the questions that correspond to missing signals.

### Interview

Before asking, tell the user: "I have a few quick questions to clarify the scope before starting codebase research."

**Ask only the questions whose corresponding signal is missing. Ask them in order, one at a time.**

#### Q1: Scope and success criteria (if signal 1 missing)

Use **AskUserQuestion**:
- question: "What does 'done' look like for this feature? What should a user be able to do when it's complete?"
- options: "Let me describe the acceptance criteria" / "The user should be able to [submit/view/configure/manage] ..." / "This is an internal/backend-only change (no user-facing behaviour)" / "I'm not sure yet — make reasonable assumptions and I'll refine the plan"

If the user selects "make reasonable assumptions", note this and **skip all remaining questions** — proceed to synthesis with assumptions noted.

#### Q2: Layers involved (if signal 2 missing)

Use **AskUserQuestion**:
- question: "Which layers does this feature touch?"
- options: "Backend only (API/data/business logic)" / "Frontend only (UI components/pages)" / "Full-stack (backend API + frontend UI)" / "Full-stack + admin configuration" / "Full-stack + transactional emails" / "Let me specify: ..."

#### Q3: Data model (if signal 3 missing)

Use **AskUserQuestion**:
- question: "What data does this feature work with? Describe the key fields/attributes, or point me to an existing model to extend."
- options: "New entity with these fields: ..." / "Extends an existing entity — add fields to [entity name]" / "No new data model — uses existing data only" / "I'm not sure — propose a data model in the plan"

#### Q4: UI interaction pattern (if signal 4 missing AND feature involves frontend)

Skip this question if the user answered "Backend only" in Q2 or if the requirements clearly describe a backend-only feature.

Use **AskUserQuestion**:
- question: "How does the user interact with this feature?"
- options: "A form (single page)" / "A multi-step form / wizard" / "A listing or table with search/filter" / "A modal or drawer triggered from an existing page" / "A new standalone page" / "Other: ..."

#### Q5: Error handling (if signal 5 missing)

Use **AskUserQuestion**:
- question: "Are there specific error cases or edge conditions to handle?"
- options: "Standard validation only (required fields, format checks)" / "Yes, specific cases: ..." / "Fail gracefully with user-friendly messages — no specific cases defined" / "Skip — I'll add edge cases after seeing the initial plan"

#### Q6: Integration dependencies (if signal 6 missing)

Use **AskUserQuestion**:
- question: "Does this feature integrate with any external services or existing modules?"
- options: "No external integrations" / "Sends email notifications" / "Calls a third-party API: ..." / "Extends an existing module: [module name]" / "Multiple integrations — let me describe: ..."

### Synthesize interview into supplement

After the interview (or after confirming a previous supplement), write a requirements supplement file.

**File path:** `docs/requirements/<TICKET>/interview-supplement.md` — derive `<TICKET>` from:
- The ticket identifier extracted in Phase 0 (branch name or $ARGUMENTS)
- If no ticket identifier, use a kebab-case slug from the feature description (e.g. `hire-request-form`)

**Format:**

```markdown
# Interview Supplement — <TICKET or feature-name>

Generated by /plan-feature requirements interview on <date>.

## Scope and Success Criteria
<answer or "Not asked — requirements already specify acceptance criteria">

## Layers Involved
<answer or "Not asked — requirements already specify layers: [list]">

## Data Model
<answer or "Not asked — requirements already describe data model">

## UI Interaction Pattern
<answer or "Not asked — [reason: backend-only / requirements describe UI / signal present]">

## Error Handling
<answer or "Not asked — requirements already address edge cases">

## Integration Dependencies
<answer or "Not asked — no external integrations identified">
```

If the interview was skipped entirely (all signals present), write:

```markdown
# Interview Supplement — <TICKET or feature-name>

Requirements assessment: COMPLETE — interview skipped.
All completeness signals present in the original requirements.
```

**Carry the interview answers forward.** When formulating codebase-qa questions in Phase 2, incorporate the interview answers to sharpen the research. For example, if the user specified "multi-step form wizard" as the UI pattern, reference the project's existing form wizard pattern in the research question. If the user specified specific layers, focus research agents on those layers.

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

## Requirements Clarification (Interview)
The following was clarified with the developer before research:

[paste full contents of interview-supplement.md, or note "Interview skipped — requirements were complete"]

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

## Milestone: Save session state

Before reporting, save transient state so it survives context compaction. Create the directory if needed (`mkdir -p docs/requirements/<TICKET>/`), then write to `docs/requirements/<TICKET>/session-state.md` (derive `<TICKET>` the same way as interview-supplement.md — branch name first, then kebab-case slug):

```markdown
# Session State — <TICKET>

| Field | Value |
|-------|-------|
| Workflow | plan-feature |
| Last completed phase | 4 |
| Ticket | <TICKET> |
| Branch | <branch name from Phase 0> |
| Plan file | <path to the plan file produced by the feature-planner agent> |
| Saved at | <ISO timestamp> |

## Agent Activity Summary

| # | Agent Type | Question / Target | Key Finding |
|---|---|---|---|
| 1 | codebase-qa | <question> | <one-line summary> |
| ... | ... | ... | ... |
| N | feature-planner | <prompt summary> | <one-line summary> |

**Totals:** X codebase-qa agents, Y impact-analyser agents, Z total.

## Interview Status

<"X questions asked, answers saved to <path>" OR "Skipped — requirements complete">

## Open Questions Count

<number of open questions in the plan>
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

3. Interview status: "X questions asked, answers saved to [path]" or "skipped — requirements complete"
4. The number of open questions in the plan
5. A reminder: "Review the plan at [path]. Verify you can explain the feature's data flow end-to-end before running the feature-implementer."
