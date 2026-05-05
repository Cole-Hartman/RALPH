#!/bin/bash
################################################################################
# RALPH - Autonomous AI Loop Runner
#
# Expected state files:
#   .ralph/prompt.md
#   .ralph/PRD.md
#   .ralph/TRACK.md
#   .ralph/progress.txt
#
# Usage:
#   ./.ralph/ralph.sh
#
# Environment:
#   RALPH_NO_PR=1    # Disable PR creation
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

# Create PR once at start if gh is available
if command -v gh >/dev/null 2>&1 && [ "${RALPH_NO_PR:-0}" != "1" ]; then
    if git remote get-url origin >/dev/null 2>&1; then
        echo "Pushing $CURRENT_BRANCH to origin..."
        git push -u origin "$CURRENT_BRANCH" 2>/dev/null || true

        PR_URL=$(gh pr list --head "$CURRENT_BRANCH" --json url -q '.[0].url' 2>/dev/null || true)
        if [ -z "$PR_URL" ]; then
            echo "Creating PR from $CURRENT_BRANCH..."
            gh pr create \
                -H "$CURRENT_BRANCH" \
                --title "WIP: $CURRENT_BRANCH" \
                --body "Ralph implementation track. See .ralph/PRD.md, .ralph/TRACK.md, and .ralph/progress.txt." 2>/dev/null || true
        fi
    fi
fi

echo "Starting Ralph - 10 iterations max"
echo "Project: $PROJECT_ROOT"
echo "Branch: $CURRENT_BRANCH"
echo ""

for ((i=1; i<=10; i++)); do
    REMAINING=$(awk '/^### \[ \] / { count++ } END { print count + 0 }' "$TRACK_FILE")

    if [ "$REMAINING" -eq 0 ]; then
        echo ""
        echo "SUCCESS - All Ralph tasks are complete."
        echo "Iterations used: $((i - 1)) of 10"
        exit 0
    fi

    NEXT_TASK=$(awk '/^### \[ \] / { sub(/^### \[ \] /, ""); print; exit }' "$TRACK_FILE")

    echo ""
    echo "==============================================================="
    echo "  Ralph Iteration $i of 10 | $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  Remaining tasks: $REMAINING"
    echo "  Next task: $NEXT_TASK"
    echo "==============================================================="
    echo ""

    # Build runtime metadata
    RUNTIME_PROMPT="## Ralph Runtime Metadata

Iteration: $i of 10
Project root: $PROJECT_ROOT
Current branch: $CURRENT_BRANCH
Ralph state directory: $RALPH_DIR
Next task: $NEXT_TASK

## State Files

PRD file: $PRD_FILE
TRACK file: $TRACK_FILE
Progress file: $PROGRESS_FILE

## Recent Progress

"

    # Add recent progress context if not first iteration
    if [ "$i" -gt 1 ] && [ -f "$PROGRESS_FILE" ]; then
        RUNTIME_PROMPT+="$(tail -60 "$PROGRESS_FILE")

"
    fi

    RUNTIME_PROMPT+="## Runner-Owned Responsibilities

- The shell runner will push and manage the PR after your iteration.
- The shell runner checks TRACK.md to decide whether to continue.
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

    echo "[$(date '+%H:%M:%S')] Iteration $i complete."
done

echo ""
echo "Max iterations (10) reached."
REMAINING=$(awk '/^### \[ \] / { count++ } END { print count + 0 }' "$TRACK_FILE")
echo "Remaining tasks: $REMAINING"
echo ""
echo "To continue:"
echo "  ./.ralph/ralph.sh"
exit 1
