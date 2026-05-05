---
name: prd
description: "Generate a Product Requirements Document (PRD.md) and Task Track (TRACK.md) for a new feature. Use when planning a feature, starting a new project, or when asked to create a PRD. Triggers on: create a prd, write prd for, plan this feature, requirements for, spec out."
---

################################################################################
# PRD & Track Generator Skill
#
# This skill generates structured Product Requirements Documents and Task Tracks
# optimized for autonomous AI implementation via the Ralph loop.
#
# Creates three files:
# - PRD.md: Strategic overview (goals, scope, technical considerations)
# - TRACK.md: Implementation roadmap (tasks organized by phase with acceptance criteria)
# - progress.txt: Shared state log (patterns, learnings, blockers)
#
# Key principle: Every task must be completable in one AI iteration (~10 min, one context window)
################################################################################

# PRD & Track Generator

Create detailed Product Requirements Documents and implementation tracks that are clear, actionable, and suitable for autonomous AI implementation via the Ralph loop.

---

## The Job

1. Receive a feature description from the user
2. Ask 3-5 essential clarifying questions (with lettered options)
3. Generate a structured PRD based on answers
4. Save `PRD.md` (strategic overview)
5. Save `TRACK.md` (implementation phases and tasks)
6. Create empty `progress.txt`

**Important:** Do NOT start implementing. Just create the PRD and TRACK.

---

## Step 1: Feature Name

First, ask for a feature name that will be used to create the track directory.

Example: "What would you like to name this feature? (e.g., 'user-auth', 'dashboard-redesign')"

This will create: `tracks/<feature-name>/`

## Step 2: Clarifying Questions

Ask only critical questions where the initial prompt is ambiguous. Focus on:

- **Problem/Goal:** What problem does this solve?
- **Core Functionality:** What are the key actions?
- **Scope/Boundaries:** What should it NOT do?
- **Success Criteria:** How do we know it's done?

### Format Questions Like This:

```
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

## Step 3: Task Sizing (THE NUMBER ONE RULE)

**Each task must be completable in ONE context window (~10 min of AI work).**

Ralph spawns a fresh instance per iteration with no memory of previous work. If a task is too big, the AI runs out of context before finishing and produces broken code.

### Right-sized tasks:
- Add a database column and migration
- Add a single UI component to an existing page
- Update a server action with new logic
- Add a filter dropdown to a list

### Too big (MUST split):
| Too Big | Split Into |
|---------|-----------|
| "Build the dashboard" | Schema, queries, UI components, filters |
| "Add authentication" | Schema, middleware, login UI, session handling |
| "Add drag and drop" | Drag events, drop zones, state update, persistence |
| "Refactor the API" | One endpoint or pattern at a time |

**Rule of thumb:** If you cannot describe the change in 2-3 sentences, it is too big.

---

## Step 4: Task Ordering (Dependencies First)

Tasks execute in priority order. Earlier tasks must NOT depend on later ones.

**Correct order:**
1. Schema/database changes (migrations)
2. Server actions / backend logic
3. UI components that use the backend
4. Dashboard/summary views that aggregate data

**Wrong order:**
```
T-001: UI component (depends on schema that doesn't exist yet!)
T-002: Schema change
```

---

## Step 5: Acceptance Criteria (Must Be Verifiable)

Each criterion must be something Ralph can CHECK, not something vague.

### Good criteria (verifiable):
- "Add `status` column to tasks table with default 'pending'"
- "Filter dropdown has options: All, Active, Completed"
- "Clicking delete shows confirmation dialog"
- "Typecheck passes"
- "Tests pass"

### Bad criteria (vague):
- "Works correctly"
- "User can do X easily"
- "Good UX"
- "Handles edge cases"

### Always include as final criterion:
```
"Typecheck passes"
```

### For stories that change UI, also include:
```
"Verify changes work in browser"
```

---

## PRD Structure

Generate the PRD with these sections:

### 1. Introduction
Brief description of the feature and the problem it solves.

### 2. Goals
Specific, measurable objectives (bullet list).

### 3. Scope & Deliverables
What's included in this feature. Clear boundaries of what will be delivered.

### 4. Non-Goals
What this feature will NOT include. Critical for scope.

### 5. Technical Considerations (Optional)
- Known constraints
- Existing components to reuse
- Architecture patterns to follow

---

## TRACK Structure

Generate the TRACK with these sections:

### 1. Overview
Summary of the implementation approach and phases.

### 2. Implementation Phases
Organize tasks by phase or logical grouping. Each phase contains:

**Format:**
```markdown
## Phase 1: [Phase Name]

### Task 1: [Title]
[2-3 sentence description of what needs to be done]

**Acceptance Criteria:**
- [ ] Specific verifiable criterion
- [ ] Another criterion
- [ ] Typecheck passes
- [ ] [UI tasks] Verify changes work in browser

### Task 2: [Title]
[Description]

**Acceptance Criteria:**
- [ ] ...
```

### 3. Dependencies & Notes
Any cross-phase dependencies or important implementation notes.

---

## Example Output

### PRD.md

```markdown
# PRD: Task Priority System

## Introduction

Add priority levels to tasks so users can focus on what matters most. Tasks can be marked as high, medium, or low priority, with visual indicators and filtering.

## Goals

- Allow assigning priority (high/medium/low) to any task
- Provide clear visual differentiation between priority levels
- Enable filtering by priority
- Default new tasks to medium priority

## Scope & Deliverables

- Priority field in database with three levels
- Visual indicators on task cards
- Priority selector in task edit interface
- Filter by priority in task list
- URL-based filter persistence

## Non-Goals

- No priority-based notifications or reminders
- No automatic priority assignment based on due date
- No priority inheritance for subtasks

## Technical Considerations

- Reuse existing badge component with color variants
- Filter state managed via URL search params
- Database migration required for priority column
```

### TRACK.md

```markdown
# Task Priority Implementation Track

## Overview

Implementation organized in three phases: database foundation, UI display, and user interaction features.

## Phase 1: Database & Foundation

### Task 1: Add priority field to database
Add the priority column to tasks table with appropriate enum type and default value.

**Acceptance Criteria:**
- [ ] Create migration file for priority column
- [ ] Priority field: 'high' | 'medium' | 'low' (default 'medium')
- [ ] Migration runs successfully
- [ ] Typecheck passes

## Phase 2: Display & Visualization

### Task 2: Display priority indicator on task cards
Show visual priority indicators on each task card.

**Acceptance Criteria:**
- [ ] Each task card shows colored priority badge (red=high, yellow=medium, gray=low)
- [ ] Priority visible without hovering or clicking
- [ ] Typecheck passes
- [ ] Verify changes work in browser

## Phase 3: User Interaction

### Task 3: Add priority selector to task edit
Allow users to change priority when editing a task.

**Acceptance Criteria:**
- [ ] Priority dropdown in task edit modal
- [ ] Shows current priority as selected
- [ ] Saves immediately on selection change
- [ ] Typecheck passes
- [ ] Verify changes work in browser

### Task 4: Filter tasks by priority
Enable filtering the task list by priority level.

**Acceptance Criteria:**
- [ ] Filter dropdown with options: All | High | Medium | Low
- [ ] Filter persists in URL params
- [ ] Empty state message when no tasks match filter
- [ ] Typecheck passes
- [ ] Verify changes work in browser

## Dependencies & Notes

- Phase 1 must complete before Phase 2 and 3
- Phases 2 and 3 can run in parallel
- Filter state should use URL search params for bookmarking
```

---

## Output

Create the directory `tracks/<feature-name>/` and save the following files inside it:

### PRD.md
Strategic overview of the feature: introduction, goals, scope, non-goals, and technical considerations.

### TRACK.md
Implementation roadmap: phases, tasks, acceptance criteria, and dependencies.

### progress.txt
Create an empty progress file:
```markdown
# Progress Log

## Learnings
(Patterns discovered during implementation)

---
```

**Important:** Make sure all three files are created in the `tracks/<feature-name>/` directory, not in the root.

---

## Checklist Before Saving

- [ ] Got feature name from user
- [ ] Created `tracks/<feature-name>/` directory
- [ ] Asked clarifying questions with lettered options
- [ ] Incorporated user's answers
- [ ] Each task completable in ONE iteration (small enough)
- [ ] Tasks ordered by dependency (schema → backend → frontend)
- [ ] All criteria are verifiable (not vague)
- [ ] Every task has "Typecheck passes" as criterion
- [ ] UI tasks have "Verify changes work in browser"
- [ ] PRD has clear introduction, goals, scope, and non-goals
- [ ] TRACK has phases with tasks and acceptance criteria
- [ ] TRACK includes dependencies section
- [ ] Saved PRD.md, TRACK.md, and progress.txt in `tracks/<feature-name>/`
