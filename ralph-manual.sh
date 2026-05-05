#!/bin/bash
################################################################################
# Ralph Manual - Run One Task at a Time
#
# Run one task, watch the output, run again when ready.
# You control when each task runs.
#
# Expected state files (run from inside ralph/ directory):
#   PRD.md
#   TRACK.md
#   progress.txt
#
# Usage:
#   cd ralph && bash ralph-manual.sh
################################################################################
set -euo pipefail

RALPH_DIR="."

# Check required files
for file in "$RALPH_DIR"/{PRD.md,TRACK.md,progress.txt}; do
    [ -f "$file" ] || { echo "Error: Missing $file"; exit 1; }
done

PROJECT_ROOT=$(git rev-parse --show-toplevel)
CURRENT_BRANCH=$(git branch --show-current)

get_current_phase() {
    awk '/^## Phase / { phase=$0; phaseline=NR } /^### \[ \] / { if (NR > phaseline && phase ~ /^## Phase/) { print phase; exit } }' "$RALPH_DIR/TRACK.md"
}

count_tasks_in_phase() {
    local phase="$1"
    awk -v phase="$phase" '
        BEGIN { in_phase=0; count=0 }
        $0 == phase { in_phase=1; next }
        /^## Phase / && in_phase { exit }
        in_phase && /^### \[ \] / { count++ }
        END { print count }
    ' "$RALPH_DIR/TRACK.md"
}

count_remaining_in_phase() {
    local phase="$1"
    awk -v phase="$phase" '
        BEGIN { in_phase=0; count=0 }
        $0 == phase { in_phase=1; next }
        /^## Phase / && in_phase { exit }
        in_phase && /^### \[ \] / { count++ }
        END { print count + 0 }
    ' "$RALPH_DIR/TRACK.md"
}

get_task() {
    local phase="$1"
    awk -v phase="$phase" '
        BEGIN { in_phase=0 }
        $0 == phase { in_phase=1; next }
        /^## Phase / && in_phase { exit }
        in_phase && /^### \[ \] / { sub(/^### \[ \] /, ""); print; exit }
    ' "$RALPH_DIR/TRACK.md"
}

CURRENT_PHASE=$(get_current_phase)

if [ -z "$CURRENT_PHASE" ]; then
    echo "All phases complete!"
    exit 0
fi

REMAINING=$(count_remaining_in_phase "$CURRENT_PHASE")

if [ "$REMAINING" -eq 0 ]; then
    echo "Current phase complete! Run again to continue to the next phase."
    exit 0
fi

# Get next task in current phase
NEXT_TASK=$(get_task "$CURRENT_PHASE")

echo ""
echo "==============================================================="
echo "  Ralph Manual - One Phase"
echo "  Branch: $CURRENT_BRANCH"
echo "  Current phase: $CURRENT_PHASE"
echo "  Remaining in phase: $REMAINING"
echo "  Next task: $NEXT_TASK"
echo "==============================================================="
echo ""

# Build prompt
PROMPT="## Ralph Manual - Complete One Phase

Project: $PROJECT_ROOT
Branch: $CURRENT_BRANCH
Current phase: $CURRENT_PHASE
Remaining in phase: $REMAINING
Next task: $NEXT_TASK

## Recent Progress

"
[ -f "$RALPH_DIR/progress.txt" ] && PROMPT+="$(tail -40 "$RALPH_DIR/progress.txt")" || PROMPT+="(No progress yet)"

PROMPT+="

## Instructions

You are an autonomous code agent. Complete the next task in the current phase:

1. Review progress.txt to understand what's been done
2. Understand the feature context from PRD.md
3. Find the next incomplete task in $CURRENT_PHASE (marked with [ ])
4. Implement the task (code + test + commit)
5. Update TRACK.md: change [ ] to [x]
6. Update progress.txt with what you accomplished

Once this task is done, the script will run again to complete the next task in the phase. Keep going until all tasks in the phase are complete."

echo "[$(date '+%H:%M:%S')] Starting Claude agent..."
echo ""

RESULT=$(claude --dangerously-skip-permissions -p "$PROMPT")

echo ""
echo "----- Claude Agent Output --------------------------------------"
echo "$RESULT"
echo "----- End Output -----------------------------------------------"
echo ""

# Check if task was completed
NEW_REMAINING=$(count_remaining_in_phase "$CURRENT_PHASE")

if [ "$NEW_REMAINING" -lt "$REMAINING" ]; then
    echo "✓ Task completed!"
else
    echo "⚠ Task may not have completed. Check TRACK.md and progress.txt."
fi

echo ""
echo "Remaining in phase: $NEW_REMAINING"
echo ""

if [ "$NEW_REMAINING" -eq 0 ]; then
    echo "Phase complete! Run this script again to move to the next phase."
else
    echo "Run this script again to complete the next task in $CURRENT_PHASE."
fi
