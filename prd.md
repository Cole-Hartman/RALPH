---
name: prd
description: "Generate Ralph planning state for a feature: ralph/PRD.md, ralph/TRACK.md, and ralph/progress.txt. Use when planning a feature, starting a new Ralph run, or asked to create a PRD. Triggers on: create a prd, write prd for, plan this feature, requirements for, spec out."
---

# PRD & Track Generator

Create Ralph state files for autonomous implementation. The output lives in the current branch under `ralph/`.

Do not implement the feature. Only plan it.

## Output Files

Create or update:

- `ralph/PRD.md` - strategic feature overview
- `ralph/TRACK.md` - ordered implementation tasks and completion state
- `ralph/progress.txt` - append-only implementation memory

The repository's `prompt.md` is used as a fixed template and should not be copied or modified.

## Workflow

1. Ask for a feature name if one was not provided.
2. Ask 3-5 essential clarifying questions with lettered options.
3. Generate `ralph/PRD.md`.
4. Generate `ralph/TRACK.md`.
5. Create `ralph/progress.txt`.
6. Confirm that all output files are under `ralph/`.

Ask only critical questions. Focus on:

- Problem/goal: what problem does this solve?
- Core functionality: what are the key user or system actions?
- Scope/boundaries: what should this not do?
- Success criteria: how do we know it is done?
- Technical constraints: existing APIs, components, migrations, or test expectations.

Question format:

```text
1. What is the primary goal of this feature?
   A. Improve user onboarding
   B. Reduce support burden
   C. Add an internal admin workflow
   D. Other: [please specify]

2. What scope should Ralph implement?
   A. Minimal viable version
   B. Full user-facing workflow
   C. Backend/API only
   D. UI only
```

## Task Rules

Every task must fit one Ralph iteration: one focused context window and one commit.

Good task size:

- Add a database column and migration.
- Add one UI component to an existing page.
- Update one server action or endpoint.
- Add one filter or control to an existing view.

Too large:

- "Build the dashboard."
- "Add authentication."
- "Refactor the API."
- "Add drag and drop."

Split large work by dependency order:

1. Schema/data model.
2. Backend/API/server actions.
3. UI that consumes the backend.
4. Browser verification, polish, and edge states.

Acceptance criteria must be verifiable. Avoid vague wording like "works well" or "good UX."

Every task must include:

- `Typecheck passes.`

Tasks with testable logic should include:

- `Tests pass.`

UI tasks should include:

- `Verify changes work in browser.`

## TRACK Format

Task headings are the only completion markers Ralph reads. Use this exact format:

```markdown
### [ ] T-001: Add priority field to database
```

Ralph marks completion by changing it to:

```markdown
### [x] T-001: Add priority field to database
```

Important:

- Use sequential IDs: `T-001`, `T-002`, `T-003`.
- Do not use checkbox bullets for acceptance criteria.
- Acceptance criteria are normal bullets.
- Put tasks in execution order.

## PRD Template

Write `ralph/PRD.md` like this:

```markdown
# PRD: [Feature Name]

## Introduction

[Brief description of the feature and problem.]

## Goals

- [Specific objective]

## Scope & Deliverables

- [Included deliverable]

## Non-Goals

- [Explicitly out of scope]

## Technical Considerations

- [Known constraints, existing patterns, components, APIs, migrations, or tests.]
```

## TRACK Template

Write `ralph/TRACK.md` like this:

```markdown
# [Feature Name] Implementation Track

## Overview

[Short implementation strategy and dependency order.]

## Phase 1: [Phase Name]

### [ ] T-001: [Task Title]
[Two or three sentences describing the exact implementation work.]

Acceptance Criteria:
- [Specific verifiable criterion.]
- Typecheck passes.

### [ ] T-002: [Task Title]
[Two or three sentences describing the exact implementation work.]

Acceptance Criteria:
- [Specific verifiable criterion.]
- Tests pass.
- Typecheck passes.

## Dependencies & Notes

- [Important ordering, reuse, or integration note.]
```

## progress.txt Template

Write `ralph/progress.txt` like this:

```markdown
# Ralph Progress Log

## Learnings

(Reusable patterns discovered during implementation.)

---
```

## Example

`ralph/TRACK.md` example:

```markdown
# Task Priority System Implementation Track

## Overview

Implementation is ordered from persistence through user interaction: add the database field, display priority, edit priority, then filter by priority.

## Phase 1: Data Model

### [ ] T-001: Add priority field to tasks
Add a priority field to the tasks data model and persist it with existing task records.

Acceptance Criteria:
- Priority supports high, medium, and low values.
- New tasks default to medium priority.
- Migration or schema update runs successfully.
- Typecheck passes.

## Phase 2: User Interface

### [ ] T-002: Display priority on task cards
Show each task's priority in the existing task card UI using the local badge or status style.

Acceptance Criteria:
- Each task card shows its priority.
- Priority is visible without hover.
- Typecheck passes.
- Verify changes work in browser.

### [ ] T-003: Add priority editing
Allow users to change a task's priority from the existing edit flow.

Acceptance Criteria:
- Edit UI shows the current priority.
- User can choose high, medium, or low.
- Saved priority persists after refresh.
- Typecheck passes.
- Verify changes work in browser.

## Dependencies & Notes

- T-001 must complete before T-002 or T-003.
- Reuse existing task update patterns.
```

## Checklist

- [ ] Created `ralph/`.
- [ ] Created `ralph/PRD.md`.
- [ ] Created `ralph/TRACK.md`.
- [ ] Created `ralph/progress.txt`.
- [ ] Asked only necessary clarifying questions.
- [ ] Tasks are small enough for one Ralph iteration.
- [ ] Tasks are ordered by dependency.
- [ ] Every task heading uses `### [ ] T-001:` format.
- [ ] Acceptance criteria use normal bullets, not checkboxes.
- [ ] Every task includes `Typecheck passes.`
- [ ] UI tasks include browser verification.
