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

# Check required files
for file in "$RALPH_DIR"/{prompt.md,PRD.md,TRACK.md,progress.txt}; do
    [ -f "$file" ] || { echo "Error: Missing $file"; exit 1; }
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

count_tasks() { awk '/^### \[ \] / { count++ } END { print count + 0 }' "$RALPH_DIR/TRACK.md"; }
get_task() { awk '/^### \[ \] / { sub(/^### \[ \] /, ""); print; exit }' "$RALPH_DIR/TRACK.md"; }

for ((i=1; i<=10; i++)); do
    REMAINING=$(count_tasks)

    if [ "$REMAINING" -eq 0 ]; then
        echo ""
        echo "SUCCESS - All Ralph tasks are complete."
        echo "Iterations used: $((i - 1)) of 10"
        exit 0
    fi

    NEXT_TASK=$(get_task)

    echo ""
    echo "==============================================================="
    echo "  Ralph Iteration $i of 10 | $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  Remaining tasks: $REMAINING"
    echo "  Next task: $NEXT_TASK"
    echo "==============================================================="
    echo ""

    # Build prompt with runtime context
    PROMPT="## Ralph Runtime Metadata

Iteration: $i of 10
Project: $PROJECT_ROOT
Branch: $CURRENT_BRANCH
Next task: $NEXT_TASK

## Recent Progress
"
    [ "$i" -gt 1 ] && PROMPT+="$(tail -60 "$RALPH_DIR/progress.txt")" || PROMPT+="(First iteration)"

    PROMPT+="

## Runner Responsibilities

- Push and manage the PR after your iteration
- Check TRACK.md to decide whether to continue

$(cat "$RALPH_DIR/prompt.md")"

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
echo "Remaining tasks: $(count_tasks)"
echo ""
echo "To continue, run this script again from your project root."
exit 1
