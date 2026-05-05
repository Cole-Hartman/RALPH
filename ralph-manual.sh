#!/bin/bash
################################################################################
# Ralph Manual - Run One Task at a Time
#
# Run one task, watch the output, run again when ready.
# You control when each task runs.
#
# Expected state files:
#   ralph/PRD.md
#   ralph/TRACK.md
#   ralph/progress.txt
#
# Usage:
#   bash ralph/ralph-manual.sh
################################################################################
set -euo pipefail

RALPH_DIR="ralph"

# Check required files
for file in "$RALPH_DIR"/{PRD.md,TRACK.md,progress.txt}; do
    [ -f "$file" ] || { echo "Error: Missing $file"; exit 1; }
done

PROJECT_ROOT=$(git rev-parse --show-toplevel)
CURRENT_BRANCH=$(git branch --show-current)

count_tasks() { awk '/^### \[ \] / { count++ } END { print count + 0 }' "$RALPH_DIR/TRACK.md"; }
get_task() { awk '/^### \[ \] / { sub(/^### \[ \] /, ""); print; exit }' "$RALPH_DIR/TRACK.md"; }

REMAINING=$(count_tasks)

if [ "$REMAINING" -eq 0 ]; then
    echo "All tasks complete!"
    exit 0
fi

# Get next task
NEXT_TASK=$(get_task)

echo ""
echo "==============================================================="
echo "  Ralph Manual - One Task"
echo "  Branch: $CURRENT_BRANCH"
echo "  Remaining tasks: $REMAINING"
echo "  Next task: $NEXT_TASK"
echo "==============================================================="
echo ""

# Build prompt
PROMPT="## Ralph Manual - One Task

Project: $PROJECT_ROOT
Branch: $CURRENT_BRANCH
Next task: $NEXT_TASK
Remaining: $REMAINING

## Recent Progress

"
[ -f "$RALPH_DIR/progress.txt" ] && PROMPT+="$(tail -40 "$RALPH_DIR/progress.txt")" || PROMPT+="(No progress yet)"

PROMPT+="

## Instructions

You are an autonomous code agent. Complete ONE task from TRACK.md:

1. Review progress.txt to understand what's been done
2. Understand the feature context from PRD.md
3. Find the next incomplete task (marked with [ ])
4. Implement the task (code + test + commit)
5. Update TRACK.md: change [ ] to [x]
6. Update progress.txt with what you accomplished

Focus on ONE task well. Don't rush or skip steps."

echo "[$(date '+%H:%M:%S')] Starting Claude agent..."
echo ""

RESULT=$(claude --dangerously-skip-permissions -p "$PROMPT")

echo ""
echo "----- Claude Agent Output --------------------------------------"
echo "$RESULT"
echo "----- End Output -----------------------------------------------"
echo ""

# Check if task was completed
NEW_REMAINING=$(count_tasks)

if [ "$NEW_REMAINING" -lt "$REMAINING" ]; then
    echo "✓ Task completed!"
else
    echo "⚠ Task may not have completed. Check TRACK.md and progress.txt."
fi

echo ""
echo "Remaining tasks: $NEW_REMAINING"
echo ""
echo "Run this script again to do the next task."
