#!/bin/bash
################################################################################
# Ralph HITL - Human-In-The-Loop Task Runner
#
# Run one task, watch the output, run again when ready.
# No automatic spinup—you stay in control.
#
# Expected state files:
#   .ralph/PRD.md
#   .ralph/TRACK.md
#   .ralph/progress.txt
#
# Usage:
#   bash .ralph/ralph-manual.sh
################################################################################
set -euo pipefail

RALPH_DIR=".ralph"
PRD_FILE="$RALPH_DIR/PRD.md"
TRACK_FILE="$RALPH_DIR/TRACK.md"
PROGRESS_FILE="$RALPH_DIR/progress.txt"

# Check state files exist
for file in "$PRD_FILE" "$TRACK_FILE" "$PROGRESS_FILE"; do
    if [ ! -f "$file" ]; then
        echo "Error: Required Ralph state file not found: $file"
        exit 1
    fi
done

PROJECT_ROOT=$(git rev-parse --show-toplevel)
CURRENT_BRANCH=$(git branch --show-current)

# Count remaining tasks
REMAINING=$(awk '/^### \[ \] / { count++ } END { print count + 0 }' "$TRACK_FILE")

if [ "$REMAINING" -eq 0 ]; then
    echo "All tasks complete!"
    exit 0
fi

# Get next task
NEXT_TASK=$(awk '/^### \[ \] / { sub(/^### \[ \] /, ""); print; exit }' "$TRACK_FILE")

echo ""
echo "==============================================================="
echo "  Ralph HITL - One Task"
echo "  Branch: $CURRENT_BRANCH"
echo "  Remaining tasks: $REMAINING"
echo "  Next task: $NEXT_TASK"
echo "==============================================================="
echo ""

# Build runtime metadata
RUNTIME_PROMPT="## Ralph HITL Runtime Metadata

Project root: $PROJECT_ROOT
Current branch: $CURRENT_BRANCH
Ralph state directory: $RALPH_DIR
Next task: $NEXT_TASK
Remaining tasks: $REMAINING

## State Files

PRD file: $PRD_FILE
TRACK file: $TRACK_FILE
Progress file: $PROGRESS_FILE

## Recent Progress

"

# Add recent progress context
if [ -f "$PROGRESS_FILE" ]; then
    RUNTIME_PROMPT+="$(tail -40 "$PROGRESS_FILE")

"
fi

RUNTIME_PROMPT+="## Runner-Owned Responsibilities

- You will manually run the script each time.
- You check TRACK.md to see remaining tasks.
"

PROMPT="$RUNTIME_PROMPT

## Instructions

You are an autonomous code agent. Your job is to complete one task from TRACK.md.

1. Read the PRD to understand the feature context
2. Find the next incomplete task in TRACK.md (marked with [ ])
3. Implement the task:
   - Make the necessary code changes
   - Test your work
   - Commit your changes with clear messages
   - Update TRACK.md: change [ ] to [x] for completed task
4. Update progress.txt with what you accomplished and any learnings

Focus on completing ONE task well. Don't skip steps or rush.

## Files

- PRD.md: Feature requirements and goals
- TRACK.md: Tasks with status checkboxes
- progress.txt: Iteration log for context in future runs"

echo "[$(date '+%H:%M:%S')] Starting Claude agent..."
echo ""

RESULT=$(claude --dangerously-skip-permissions -p "$PROMPT")

echo ""
echo "----- Claude Agent Output --------------------------------------"
echo "$RESULT"
echo "----- End Output -----------------------------------------------"
echo ""

# Check if task was completed
NEW_REMAINING=$(awk '/^### \[ \] / { count++ } END { print count + 0 }' "$TRACK_FILE")

if [ "$NEW_REMAINING" -lt "$REMAINING" ]; then
    echo "✓ Task completed!"
else
    echo "⚠ Task may not have completed. Check TRACK.md and progress.txt."
fi

echo ""
echo "Remaining tasks: $NEW_REMAINING"
echo ""
echo "Run this script again to do the next task."
