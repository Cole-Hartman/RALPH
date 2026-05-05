# Ralph HITL - Human-In-The-Loop

Same as Ralph, but you stay in control. Run one task at a time, watch the output, then decide when to run the next task.

## Why HITL?

- **Build intuition** - See each task complete before the next one starts
- **Debug faster** - Catch failures immediately, adjust mid-track if needed
- **Stay engaged** - Don't go fully AFK; be present for each iteration
- **More control** - Manually verify progress before proceeding

## Setup

Same as Ralph:

```bash
mkdir -p .ralph && cp ~/RALPH/ralph-hitl/hitl.sh .ralph/
```

Then run the `/prd` skill to generate state files:
- `.ralph/PRD.md` - Feature overview
- `.ralph/TRACK.md` - Implementation tasks
- `.ralph/progress.txt` - Iteration log
- `.ralph/prompt.md` - Agent instructions

## Usage

```bash
./.ralph/hitl.sh
```

This:
1. Checks for remaining tasks in TRACK.md
2. Gets the next incomplete task
3. Calls Claude once with context
4. Shows the output
5. Exits (doesn't loop)

Check the output. If the task completed:
- TRACK.md was updated: `### [ ]` → `### [x]`
- progress.txt was appended with learnings

Then run again when ready:
```bash
./.ralph/hitl.sh
```

## When to Use HITL vs Ralph

| Scenario | Use |
|----------|-----|
| Testing a new feature track | HITL - build confidence first |
| Known stable pattern | Ralph - full automation |
| Debugging mid-feature | HITL - manual control |
| Familiar, high-confidence work | Ralph - set and forget |

## Inspect State

```bash
# See remaining tasks
cat .ralph/TRACK.md

# See recent iterations
tail -40 .ralph/progress.txt

# See PRD
cat .ralph/PRD.md
```
