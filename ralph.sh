#!/bin/bash
################################################################################
# RALPH - Inside-Worktree Autonomous AI Loop Runner
#
# Run this from an already-created feature worktree. Ralph does not create,
# switch, or remove worktrees. The current checkout is the agent's world.
#
# Expected state files:
#   .ralph/prompt.md
#   .ralph/PRD.md
#   .ralph/TRACK.md
#   .ralph/progress.txt
#
# Usage:
#   ./.ralph/ralph.sh                 # 10 iterations, 2s delay
#   ./.ralph/ralph.sh 20              # 20 iterations, 2s delay
#   ./.ralph/ralph.sh 20 5            # 20 iterations, 5s delay
#
# Environment:
#   RALPH_DIR=.ralph                  # Override state directory
#   RALPH_BASE_BRANCH=main            # Override PR base branch
#   RALPH_NO_PR=1                     # Disable push/PR automation
################################################################################
set -euo pipefail

MAX=${1:-10}
SLEEP=${2:-2}

if ! [[ "$MAX" =~ ^[0-9]+$ ]] || ! [[ "$SLEEP" =~ ^[0-9]+$ ]]; then
    echo "Usage: $0 [max_iterations] [sleep_seconds]"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
    echo "Error: Ralph must be run from inside a git worktree."
    exit 1
fi

cd "$PROJECT_ROOT"

if [ -z "${RALPH_DIR:-}" ]; then
    if [ "$(basename "$SCRIPT_DIR")" = ".ralph" ]; then
        RALPH_DIR="$SCRIPT_DIR"
    else
        RALPH_DIR="$PROJECT_ROOT/.ralph"
    fi
elif [[ "$RALPH_DIR" != /* ]]; then
    RALPH_DIR="$PROJECT_ROOT/$RALPH_DIR"
fi

PRD_FILE="$RALPH_DIR/PRD.md"
TRACK_FILE="$RALPH_DIR/TRACK.md"
PROGRESS_FILE="$RALPH_DIR/progress.txt"
PROMPT_FILE="$RALPH_DIR/prompt.md"

for file in "$PROMPT_FILE" "$PRD_FILE" "$TRACK_FILE" "$PROGRESS_FILE"; do
    if [ ! -f "$file" ]; then
        echo "Error: Required Ralph state file not found: $file"
        echo "Run the /prd skill in this worktree first, or create the .ralph files manually."
        exit 1
    fi
done

CURRENT_BRANCH=$(git branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    echo "Error: Ralph cannot run from a detached HEAD."
    exit 1
fi

detect_base_branch() {
    if [ -n "${RALPH_BASE_BRANCH:-}" ]; then
        echo "$RALPH_BASE_BRANCH"
        return
    fi

    local origin_head
    origin_head=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || true)
    if [ -n "$origin_head" ]; then
        echo "$origin_head"
        return
    fi

    if git show-ref --verify --quiet refs/heads/main; then
        echo "main"
        return
    fi

    if git show-ref --verify --quiet refs/heads/master; then
        echo "master"
        return
    fi

    echo ""
}

BASE_BRANCH=$(detect_base_branch)
if [ -z "$BASE_BRANCH" ]; then
    echo "Error: Could not detect base branch. Set RALPH_BASE_BRANCH=main and retry."
    exit 1
fi

if [ "$CURRENT_BRANCH" = "$BASE_BRANCH" ]; then
    echo "Error: Ralph is running on '$BASE_BRANCH'. Create and cd into a feature worktree first."
    exit 1
fi

BASE_REF="$BASE_BRANCH"
if git show-ref --verify --quiet "refs/remotes/origin/$BASE_BRANCH"; then
    BASE_REF="origin/$BASE_BRANCH"
fi

FEATURE_NAME=$(awk '/^# / { sub(/^# /, ""); print; exit }' "$TRACK_FILE")
if [ -z "$FEATURE_NAME" ]; then
    FEATURE_NAME="$CURRENT_BRANCH"
fi

task_count() {
    awk '/^### \[[ xX]\] / { count++ } END { print count + 0 }' "$TRACK_FILE"
}

incomplete_count() {
    awk '/^### \[ \] / { count++ } END { print count + 0 }' "$TRACK_FILE"
}

next_task() {
    awk '/^### \[ \] / { sub(/^### \[ \] /, ""); print; exit }' "$TRACK_FILE"
}

get_pr_url() {
    if command -v gh >/dev/null 2>&1; then
        gh pr list --head "$CURRENT_BRANCH" --json url -q '.[0].url' 2>/dev/null || true
    fi
}

commits_ahead() {
    git rev-list --count "$BASE_REF..HEAD" 2>/dev/null || echo "0"
}

ensure_pr() {
    if [ "${RALPH_NO_PR:-0}" = "1" ]; then
        return 0
    fi

    if ! command -v gh >/dev/null 2>&1; then
        echo "GitHub CLI not found; skipping PR automation."
        return 0
    fi

    if ! git remote get-url origin >/dev/null 2>&1; then
        echo "No origin remote configured; skipping push and PR automation."
        return 0
    fi

    local ahead
    ahead=$(commits_ahead)
    if [ "$ahead" -eq 0 ]; then
        echo "No commits ahead of $BASE_REF yet; PR not created."
        return 0
    fi

    echo "Pushing $CURRENT_BRANCH to origin..."
    if ! git push -u origin "$CURRENT_BRANCH"; then
        echo "Warning: git push failed; skipping PR creation for now."
        return 0
    fi

    local pr_url
    pr_url=$(get_pr_url)
    if [ -n "$pr_url" ]; then
        echo "PR: $pr_url"
        return 0
    fi

    echo "Creating PR from $CURRENT_BRANCH to $BASE_BRANCH..."
    if gh pr create \
        -B "$BASE_BRANCH" \
        -H "$CURRENT_BRANCH" \
        --title "WIP: $FEATURE_NAME" \
        --body "Ralph implementation track. See .ralph/PRD.md, .ralph/TRACK.md, and .ralph/progress.txt on this branch while the run is active."; then
        pr_url=$(get_pr_url)
        if [ -n "$pr_url" ]; then
            echo "PR created: $pr_url"
        fi
    else
        echo "Warning: PR creation failed; continuing."
    fi
}

finish_success() {
    local iterations_used=$1

    ensure_pr
    echo ""
    echo "SUCCESS - All Ralph tasks are complete."
    echo "Iterations used: $iterations_used of $MAX"
    echo "Branch: $CURRENT_BRANCH"
    echo ""
    echo "Before merging, remove Ralph run files if you do not want them in the final PR diff:"
    echo "  git rm -r .ralph"
    echo "  git commit -m \"chore: remove Ralph run files\""
    echo "  git push"
    exit 0
}

TASK_COUNT=$(task_count)
if [ "$TASK_COUNT" -eq 0 ]; then
    echo "Error: $TRACK_FILE has no Ralph task headings."
    echo "Expected task headings like: ### [ ] T-001: Add database field"
    exit 1
fi

echo "Starting Ralph - Max $MAX iterations"
echo "Project: $PROJECT_ROOT"
echo "State: $RALPH_DIR"
echo "Feature: $FEATURE_NAME"
echo "Branch: $CURRENT_BRANCH"
echo "Base: $BASE_BRANCH"
echo ""

for ((i=1; i<=MAX; i++)); do
    REMAINING=$(incomplete_count)
    if [ "$REMAINING" -eq 0 ]; then
        finish_success "$((i - 1))"
    fi

    NEXT_TASK=$(next_task)

    echo ""
    echo "==============================================================="
    echo "  Ralph Iteration $i of $MAX | $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  Branch: $CURRENT_BRANCH"
    echo "  Remaining tasks: $REMAINING"
    echo "  Next task: $NEXT_TASK"
    echo "==============================================================="
    echo ""

    FAILURE_CONTEXT=""
    if [ "$i" -gt 1 ] && [ -f "$PROGRESS_FILE" ]; then
        LAST_ENTRY=$(awk '
            /^## Iteration / { entry=$0 ORS; next }
            entry != "" { entry=entry $0 ORS }
            END { printf "%s", entry }
        ' "$PROGRESS_FILE" | tail -60)

        if [[ "$LAST_ENTRY" == *"FAILED"* ]] || [[ "$LAST_ENTRY" == *"failed"* ]] || [[ "$LAST_ENTRY" == *"Error"* ]]; then
            FAILURE_CONTEXT="

PREVIOUS ITERATION MAY HAVE FAILED - read this carefully:

$LAST_ENTRY"
        fi
    fi

    echo "[$(date '+%H:%M:%S')] Starting Claude agent..."
    echo ""

    RUNTIME_PROMPT="## Ralph Runtime Metadata

Iteration: $i of $MAX
Project root: $PROJECT_ROOT
Current branch: $CURRENT_BRANCH
Base branch: $BASE_BRANCH
Ralph state directory: $RALPH_DIR
Next task: $NEXT_TASK

## State Files

PRD file:
- $PRD_FILE

TRACK file:
- $TRACK_FILE

Progress file:
- $PROGRESS_FILE

## Runner-Owned Responsibilities

- The shell runner handles push and PR creation after your iteration.
- The shell runner checks TRACK.md after your iteration to decide whether to continue.

"

    PROMPT="$RUNTIME_PROMPT
$(cat "$PROMPT_FILE")$FAILURE_CONTEXT"

    RESULT=$(claude --dangerously-skip-permissions -p "$PROMPT")

    echo ""
    echo "----- Claude Agent Output --------------------------------------"
    echo "$RESULT"
    echo "----- End Output -----------------------------------------------"
    echo ""

    REMAINING=$(incomplete_count)
    ensure_pr

    if [ "$REMAINING" -eq 0 ]; then
        finish_success "$i"
    fi

    echo "[$(date '+%H:%M:%S')] Iteration $i complete. Remaining tasks: $REMAINING. Waiting ${SLEEP}s..."
    sleep "$SLEEP"
done

REMAINING=$(incomplete_count)
PR_URL=$(get_pr_url)

echo ""
echo "Max iterations ($MAX) reached."
echo "Remaining tasks: $REMAINING"
echo "Branch: $CURRENT_BRANCH"
if [ -n "$PR_URL" ]; then
    echo "PR: $PR_URL"
fi
echo ""
echo "To continue:"
echo "  ./.ralph/ralph.sh 20"
echo ""
echo "To inspect:"
echo "  cat $TRACK_FILE"
echo "  tail -80 $PROGRESS_FILE"
exit 1
