# RALPH: The Autonomous Implementation Loop

RALPH is a system for breaking down software features into small, autonomously completable tasks and iteratively implementing them with an AI agent.

## The Core Insight

The fundamental constraint: **each task must be completable in a single AI context window** (~10 minutes of work). When tasks are too large, the AI runs out of context, produces broken code, and the loop fails.

## How It Works

### 1. Planning Phase: PRD & TRACK
A human writes a **PRD** (Product Requirements Document) that describes *what* to build, then creates a **TRACK** that describes *how* to build it.

The TRACK breaks the feature into small, ordered tasks:
- **Right-sized**: Each task takes ~10 min to complete and produces working code
- **Ordered by dependency**: Schema → Backend → Frontend (no task depends on a later one)
- **Verifiable criteria**: Each task has acceptance criteria an AI can check

### 2. Execution Phase: Ralph Loop
A script runs in iterations:
1. Read PRD.md (what are we building?)
2. Read TRACK.md (what's the plan?)
3. Find the first incomplete task
4. Check progress.txt for learnings from previous iterations
5. Implement that ONE task
6. Run tests—if they pass, commit and mark complete; if they fail, log the failure
7. Repeat until all tasks are done

Each iteration is fresh AI with no memory of previous work, so **documenting learnings is critical**.

## The Key Rules

### Task Sizing (The #1 Rule)
If you cannot describe a task in 2–3 sentences, it is too big.

❌ **Too big**: "Build the dashboard"
✅ **Right-sized**: "Add a status column to the tasks table with default 'pending'"

### Task Ordering
Tasks must execute in dependency order. You cannot implement UI that uses a database column that doesn't exist yet.

**Correct order:**
1. Database schema (migrations)
2. Backend logic (queries, actions)
3. Frontend (components, pages)

### Acceptance Criteria
Criteria must be verifiable—something the AI can check or test.

❌ **Vague**: "Works correctly" / "Good UX"
✅ **Verifiable**: "Filter dropdown shows options: All, Active, Completed" / "Typecheck passes" / "Tests pass"

## File Structure

- **PRD.md**: What we're building (goals, scope, non-goals)
- **TRACK.md**: How we're building it (phases, tasks, acceptance criteria)
- **progress.txt**: What we learned (patterns, gotchas, useful context)
- **ralph.sh**: The loop script that runs iterations

## Why It Works

1. **Small tasks** → Each AI instance can complete them in one shot
2. **Clear ordering** → No blocked dependencies, no wasted iterations
3. **Progress tracking** → Future iterations learn from past ones
4. **Verified completion** → Tests confirm working code before commit
5. **Fresh context each time** → Each iteration is independent

## Getting Started

```bash
# Create a PRD and TRACK for your feature (human-written)
# Place them in the project root

# Run the loop (max 10 iterations, 2-second delay between)
./ralph.sh 10 2
```

Ralph will iteratively complete tasks until all are marked [x] in TRACK.md.

## Core Principles

1. **One task per iteration** — Focus beats scattered attempts
2. **Tiny > big** — Split until each task is solo-completable
3. **Dependency first** — Build layers bottom-up
4. **Tests before commit** — Broken code doesn't ship
5. **Document learnings** — Next iteration reads and learns from progress.txt

---

**RALPH works because it removes the need for the AI to hold an entire project in context. Each iteration only needs to know: this one task, the learnings so far, and verification that it works.**
