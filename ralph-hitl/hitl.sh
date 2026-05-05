#!/bin/bash
################################################################################
# Ralph HITL - Human-In-The-Loop Task Runner
#
# Run one task, watch the output, run again when ready.
# No automatic spinup—you stay in control.
#
# Expected state files:
#   .ralph/prompt.md
#   .ralph/PRD.md
#   .ralph/TRACK.md
#   .ralph/progress.txt
#
# Usage:
#   ./.ralph/hitl.sh
################################################################################
set -euo pipefail

RALPH_DIR=".ralph"
PRD_FILE="$RALPH_DIR/PRD.md"
TRACK_FILE="$RALPH_DIR/TRACK.md"
PROGRESS_FILE="$RALPH_DIR/progress.txt"
PROMPT_FILE="$RALPH_DIR/prompt.md"

# Check state files exist
for file in "$PROMPT_FILE" "$PRD_FILE" "$TRACK_FILE" "$PROGRESS_FILE"; do
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
$(cat "$PROMPT_FILE")"

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
echo "To run the next task:"
echo "  ./.ralph/hitl.sh"
echo ""
echo "To inspect:"
echo "  cat $TRACK_FILE"
echo "  tail -40 $PROGRESS_FILE"
