---
name: prd
description: "Generate .ralph/PRD.md, .ralph/TRACK.md, .ralph/progress.txt, and .ralph/prompt.md for a feature that will be implemented by the Ralph loop. Use when planning a feature, starting a new Ralph run, or asked to create a PRD. Triggers on: create a prd, write prd for, plan this feature, requirements for, spec out."
---

################################################################################
# PRD & Track Generator Skill
#
# This skill creates Ralph state files inside the current feature worktree.
# Ralph state is intentionally colocated with the code while the run is active:
#
# - .ralph/prompt.md: Agent instructions
# - .ralph/PRD.md: Strategic feature overview
# - .ralph/TRACK.md: Ordered implementation tasks
# - .ralph/progress.txt: Append-only agent memory
#
# Key principle: every task must fit one Ralph iteration.
################################################################################

# PRD & Track Generator

Create detailed planning files that are clear, actionable, and suitable for autonomous implementation by the Ralph loop.

Important: do not start implementing the feature. Only create the Ralph state files.

---

## The Job

1. Receive a feature description from the user.
2. Ask 3-5 essential clarifying questions with lettered options.
3. Generate a structured PRD based on the answers.
4. Save `.ralph/prompt.md` if it does not already exist.
5. Save `.ralph/PRD.md`.
6. Save `.ralph/TRACK.md`.
7. Create `.ralph/progress.txt`.

The user should run this skill from inside the feature worktree where Ralph will run.

---

## Step 1: Feature Name

Ask for a feature name if one was not provided.

Example: "What would you like to name this feature? (for example, user-auth or dashboard-redesign)"

Use this name for the PRD title and track title. Do not create `tracks/<feature-name>/`; Ralph state lives in `.ralph/`.

---

## Step 2: Clarifying Questions

Ask only critical questions where the initial prompt is ambiguous. Focus on:

- Problem/goal: What problem does this solve?
- Core functionality: What are the key actions?
- Scope/boundaries: What should it not do?
- Success criteria: How do we know it is done?

Format questions like this:

```text
1. What is the primary goal of this feature?
   A. Improve user onboarding experience
   B. Increase user retention
   C. Reduce support burden
   D. Other: [please specify]

2. Who is the target user?
   A. New users only
   B. Existing users only
   C. All users
   D. Admin users only

3. What is the scope?
   A. Minimal viable version
   B. Full-featured implementation
   C. Just the backend/API
   D. Just the UI
```

This lets users respond with "1A, 2C, 3B" for quick iteration.

---

## Step 3: Task Sizing

Every task must be completable in one Ralph iteration: roughly one focused context window.

Right-sized tasks:

- Add a database column and migration.
- Add one UI component to an existing page.
- Update one server action with new logic.
- Add a filter dropdown to a list.

Too big and must be split:

| Too Big | Split Into |
| --- | --- |
| Build the dashboard | Schema, queries, UI components, filters |
| Add authentication | Schema, middleware, login UI, session handling |
| Add drag and drop | Drag events, drop zones, state update, persistence |
| Refactor the API | One endpoint or pattern at a time |

Rule of thumb: if the task cannot be described in 2-3 sentences, it is too big.

---

## Step 4: Task Ordering

Tasks execute from top to bottom. Earlier tasks must not depend on later tasks.

Good order:

1. Schema/database changes.
2. Server actions/backend logic.
3. UI components that use the backend.
4. Summary views and polish.

Bad order:

```text
T-001: Build UI for a field that does not exist yet.
T-002: Add the database field.
```

---

## Step 5: Acceptance Criteria

Each acceptance criterion must be something Ralph can check. Avoid vague criteria.

Good criteria:

- Add `status` column to tasks table with default `pending`.
- Filter dropdown has options: All, Active, Completed.
- Clicking delete shows a confirmation dialog.
- Typecheck passes.
- Tests pass.

Bad criteria:

- Works correctly.
- User can do it easily.
- Good UX.
- Handles edge cases.

Always include:

```text
Typecheck passes.
```

For tasks with testable logic, include:

```text
Tests pass.
```

For UI tasks, include:

```text
Verify changes work in browser.
```

---

## PRD Structure

Create `.ralph/prompt.md` by copying the Ralph prompt template from this repository. If `.ralph/prompt.md` already exists, leave it in place unless the user asks you to refresh it.

The prompt template should contain the durable agent instructions. It should not contain per-run metadata such as iteration number, branch, or absolute file paths; `ralph.sh` prepends those at runtime.

Minimum `.ralph/prompt.md` content:

```markdown
# Ralph Agent Instructions

You are Ralph, an autonomous coding agent running inside an existing feature worktree. Do exactly one task per iteration.

## Boundaries

- Stay in the current git checkout.
- Do not create, switch, or remove git worktrees.
- Do not create, close, or merge pull requests. The shell runner handles push and PR creation after your iteration.
- Keep the implementation focused on the one selected task.

## Steps

1. Read the PRD for feature context.
2. Read TRACK.md for the implementation roadmap.
3. Find the first incomplete task heading marked exactly like: `### [ ] T-001: Task title`.
4. Read progress.txt, especially the Learnings section, for previous patterns and blockers.
5. Implement that one task only.
6. Run the relevant checks for this codebase.

## Critical: Only Complete If Checks Pass

If checks pass, mark only the selected task heading complete, append progress, and commit the work.
If checks fail, do not mark the task complete and do not commit broken code.
```

Create `.ralph/PRD.md` with these sections:

```markdown
# PRD: [Feature Name]

## Introduction
[Brief description of the feature and problem.]

## Goals
- [Specific measurable objective]

## Scope & Deliverables
- [Included deliverable]

## Non-Goals
- [Explicitly out of scope]

## Technical Considerations
- [Known constraints, patterns, or components to reuse]
```

---

## TRACK Structure

Create `.ralph/TRACK.md` with task headings in this exact status format:

```markdown
# [Feature Name] Implementation Track

## Overview
[Summary of the implementation approach.]

## Phase 1: [Phase Name]

### [ ] T-001: [Task Title]
[2-3 sentence description of what needs to be done.]

Acceptance Criteria:
- [Specific verifiable criterion]
- Typecheck passes.

### [ ] T-002: [Task Title]
[2-3 sentence description.]

Acceptance Criteria:
- [Specific verifiable criterion]
- Tests pass.
- Typecheck passes.

## Dependencies & Notes
- [Important dependency or implementation note.]
```

Important task-format rules:

- Every task heading must start with `### [ ] T-001:` style status.
- Use sequential task IDs: `T-001`, `T-002`, `T-003`.
- Do not use checkbox bullets for acceptance criteria. Ralph only marks task headings complete.
- Ralph marks a task complete by changing `### [ ]` to `### [x]`.

---

## progress.txt Structure

Create `.ralph/progress.txt` with:

```markdown
# Ralph Progress Log

## Learnings
(Reusable patterns discovered during implementation.)

---
```

Ralph appends iteration notes to this file. Do not prefill task-specific progress.

---

## Example Output

Create `.ralph/prompt.md` from the Ralph prompt template, then create `.ralph/PRD.md`:

```markdown
# PRD: Task Priority System

## Introduction

Add priority levels to tasks so users can focus on what matters most. Tasks can be marked as high, medium, or low priority, with visual indicators and filtering.

## Goals

- Allow assigning priority to any task.
- Provide clear visual differentiation between priority levels.
- Enable filtering by priority.
- Default new tasks to medium priority.

## Scope & Deliverables

- Priority field in the database.
- Visual indicators on task cards.
- Priority selector in task edit interface.
- Filter by priority in task list.

## Non-Goals

- No priority-based notifications.
- No automatic priority assignment based on due date.
- No priority inheritance for subtasks.

## Technical Considerations

- Reuse existing badge component with color variants.
- Filter state should use URL search params.
- Database migration is required for priority column.
```

Create `.ralph/TRACK.md`:

```markdown
# Task Priority System Implementation Track

## Overview

Implementation is organized in dependency order: database foundation, UI display, editing, and filtering.

## Phase 1: Database & Foundation

### [ ] T-001: Add priority field to database
Add the priority column to the tasks table with the appropriate enum type and default value.

Acceptance Criteria:
- Create migration file for priority column.
- Priority field supports high, medium, and low values with default medium.
- Migration runs successfully.
- Typecheck passes.

## Phase 2: Display & Interaction

### [ ] T-002: Display priority indicator on task cards
Show visual priority indicators on each task card.

Acceptance Criteria:
- Each task card shows a colored priority badge.
- Priority is visible without hovering or clicking.
- Typecheck passes.
- Verify changes work in browser.

### [ ] T-003: Add priority selector to task edit
Allow users to change priority when editing a task.

Acceptance Criteria:
- Priority dropdown appears in the task edit modal.
- Dropdown shows the current priority.
- Selection saves successfully.
- Typecheck passes.
- Verify changes work in browser.

### [ ] T-004: Filter tasks by priority
Enable filtering the task list by priority level.

Acceptance Criteria:
- Filter dropdown has options: All, High, Medium, Low.
- Filter persists in URL params.
- Empty state appears when no tasks match.
- Typecheck passes.
- Verify changes work in browser.

## Dependencies & Notes

- T-001 must complete before UI tasks.
- Filtering should reuse existing URL search param patterns.
```

Create `.ralph/progress.txt`:

```markdown
# Ralph Progress Log

## Learnings
(Reusable patterns discovered during implementation.)

---
```

---

## Checklist Before Saving

- [ ] Created `.ralph/` in the current worktree.
- [ ] Created or preserved `.ralph/prompt.md`.
- [ ] Created `.ralph/PRD.md`.
- [ ] Created `.ralph/TRACK.md`.
- [ ] Created `.ralph/progress.txt`.
- [ ] Asked clarifying questions with lettered options.
- [ ] Incorporated the user's answers.
- [ ] Each task is small enough for one Ralph iteration.
- [ ] Tasks are ordered by dependency.
- [ ] Every task heading uses `### [ ] T-001:` format.
- [ ] Acceptance criteria are verifiable and do not use checkbox bullets.
- [ ] Every task includes Typecheck passes.
- [ ] UI tasks include browser verification.
