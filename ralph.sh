#!/bin/bash
################################################################################
# RALPH - Autonomous AI Loop Orchestrator
#
# This script orchestrates an autonomous AI development loop that:
# - Creates isolated git worktrees and branches for each feature
# - Iteratively invokes Claude to implement one task per iteration
# - Tracks progress via TRACK.md (tasks) and progress.txt (learnings)
# - Automatically detects completion when all tasks are marked [x]
# - Manages GitHub PR creation and updates
#
# Usage: ./ralph.sh [track_path] [max_iterations] [sleep_seconds]
# Examples:
#   ./ralph.sh tracks/my-feature/              # Run track in tracks/my-feature
#   ./ralph.sh                                 # Run with TRACK.md in current directory
#   ./ralph.sh tracks/my-feature 20 2          # Run 20 iterations with 2s delay
################################################################################
set -e

# Handle track path argument
TRACK_PATH=${1:-.}
MAX=${2:-10}
SLEEP=${3:-2}

# If track path provided, validate and change to it
if [ "$TRACK_PATH" != "." ]; then
    if [ ! -d "$TRACK_PATH" ]; then
        echo "Error: Track directory not found: $TRACK_PATH"
        exit 1
    fi
    if [ ! -f "$TRACK_PATH/TRACK.md" ]; then
        echo "Error: TRACK.md not found in $TRACK_PATH"
        exit 1
    fi
fi

# Store the project root (before changing directories)
PROJECT_ROOT=$(pwd)

# Change to track directory if specified
if [ "$TRACK_PATH" != "." ]; then
    cd "$TRACK_PATH"
    TRACK_PATH="."
fi

# Extract feature/track name from TRACK.md or use default
FEATURE_NAME=$(grep -m1 "^# " TRACK.md 2>/dev/null | sed 's/^# //' || echo "feature")
FEATURE_BRANCH="feature/${FEATURE_NAME// /-}" # Replace spaces with hyphens, add prefix
WORKTREE_PATH="$PROJECT_ROOT/.worktrees/$FEATURE_BRANCH"
MAIN_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "Starting Ralph - Max $MAX iterations"
echo "Feature: $FEATURE_NAME"
echo "Branch: $FEATURE_BRANCH"
echo ""

# Determine if this is the first worker by checking if branch exists in git (source of truth)
IS_FIRST=0
if ! git rev-parse --verify "$FEATURE_BRANCH" >/dev/null 2>&1; then
    IS_FIRST=1
    echo "First worker detected (branch doesn't exist yet)"
else
    echo "Continuation worker detected (branch already exists)"
fi

echo ""

# Create worktree for this feature/track
if [ ! -d "$WORKTREE_PATH" ]; then
    echo "Creating dedicated worktree with branch: $FEATURE_BRANCH"
    mkdir -p .worktrees
    # Check if branch already exists (git is source of truth)
    if [ $IS_FIRST -eq 0 ]; then
        # Branch exists, add worktree from existing branch
        git worktree add "$WORKTREE_PATH" "$FEATURE_BRANCH"
        echo "Worktree created from existing branch: $FEATURE_BRANCH"
    else
        # First worker: create new branch
        git worktree add -b "$FEATURE_BRANCH" "$WORKTREE_PATH" "$MAIN_BRANCH"
        echo "Worktree created with new branch: $FEATURE_BRANCH"
    fi
else
    echo "Using existing worktree: $WORKTREE_PATH"
fi

echo ""

# Change to worktree for all work
cd "$WORKTREE_PATH"

# Check if PR already exists (will check again before creating)
PR_URL=""
if command -v gh &> /dev/null; then
    PR_URL=$(gh pr list --head "$FEATURE_BRANCH" --json url -q '.[0].url' 2>/dev/null || echo "")
    if [ -n "$PR_URL" ]; then
        echo "Existing PR found: $PR_URL"
    fi
fi

echo ""

for ((i=1; i<=$MAX; i++)); do
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  Iteration $i of $MAX  |  $(date '+%Y-%m-%d %H:%M:%S')"
    echo "║  Branch: $FEATURE_BRANCH"
    echo "║  Worktree: $WORKTREE_PATH"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Build prompt dynamically to handle PR instructions
    # Note: IS_FIRST is determined at startup based on git branch existence
    if [ $IS_FIRST -eq 1 ]; then
        if [ -z "$PR_URL" ]; then
            PR_SECTION="## FIRST WORKER: Create PR + Implement Task

After your first commit and push, create the PR with:
\`\`\`bash
gh pr create -B $MAIN_BRANCH -H $FEATURE_BRANCH --title 'WIP: $FEATURE_NAME' --body 'Track: $FEATURE_NAME. See PRD.md and TRACK.md for details.'
\`\`\`

Your commits will automatically update this PR."
        else
            PR_SECTION="## FIRST WORKER: Implement Task

PR already exists: $PR_URL
Your commits will automatically update this PR."
        fi
    else
        PR_SECTION="## CONTINUATION WORKER: Implement Task (PR already created)

Previous worker created the PR. Your commits automatically update it."
    fi

    # Extract last failure/blocker if this isn't the first iteration
    FAILURE_CONTEXT=""
    if [ $IS_FIRST -eq 0 ] && [ -f "progress.txt" ]; then
        # Get the last iteration entry (most recent failure)
        LAST_ENTRY=$(tac progress.txt | sed -n '/^## Iteration/,/^---$/p' | tac | head -20)
        if [[ "$LAST_ENTRY" == *"FAILED"* ]] || [[ "$LAST_ENTRY" == *"failed"* ]] || [[ "$LAST_ENTRY" == *"Error"* ]]; then
            FAILURE_CONTEXT="

⚠️  PREVIOUS ITERATION FAILED - Read this carefully:

$LAST_ENTRY"
        fi
    fi

    # Create temp file to capture output while streaming to terminal
    ITERATION_OUTPUT=$(mktemp)
    trap "rm -f $ITERATION_OUTPUT" EXIT

    echo "[$(date '+%H:%M:%S')] Starting Claude agent..."
    echo ""

    result=$(claude --dangerously-skip-permissions -p "You are Ralph, an autonomous coding agent. Do exactly ONE task per iteration.

## Metadata

Iteration: $i of $MAX
Worker Role: $([ $IS_FIRST -eq 1 ] && echo 'FIRST (creates/uses PR)' || echo 'CONTINUATION')

## Environment

Worktree: $WORKTREE_PATH
Branch: $FEATURE_BRANCH
All work is isolated. Commits go to this branch only.

$PR_SECTION"

## Steps

1. Read PRD.md for the feature overview
2. Read TRACK.md for the implementation roadmap
3. Find the first task that is NOT complete (marked [ ]).
4. Read progress.txt - check the Learnings section first for patterns from previous iterations.
5. Implement that ONE task only.
6. Run tests/typecheck to verify it works.

## Critical: Only Complete If Tests Pass

- If tests PASS:
  - Update TRACK.md to mark the task complete (change [ ] to [x])
  - Commit your changes with message: feat: [task description]
  - Append what worked to progress.txt

- If tests FAIL:
  - Do NOT mark the task complete
  - Do NOT commit broken code
  - Append what went wrong to progress.txt (so next iteration can learn)

## Progress Notes Format

Append to progress.txt using this format:

## Iteration [N] - [Task Name]
- What was implemented
- Files changed
- Learnings for future iterations:
  - Patterns discovered
  - Gotchas encountered
  - Useful context
---

## Update AGENTS.md (If Applicable)

If you discover a reusable pattern that future work should know about:
- Check if AGENTS.md exists in the project root
- Add patterns like: 'This codebase uses X for Y' or 'Always do Z when changing W'
- Only add genuinely reusable knowledge, not task-specific details

## End Condition

Just end your response when done. The system will check if all tasks are [x] and continue or complete.$FAILURE_CONTEXT")

    # Display the result with section header
    echo ""
    echo "─── Claude Agent Output ───────────────────────────────────────"
    echo "$result" | tee "$ITERATION_OUTPUT"
    echo "─── End Output ────────────────────────────────────────────────"
    echo ""

    # Check if all tasks are complete by counting incomplete markers in TRACK.md
    INCOMPLETE_COUNT=$(grep -c "^- \[ \]" TRACK.md 2>/dev/null || echo "1")

    if [ "$INCOMPLETE_COUNT" -eq 0 ]; then
        cd "$PROJECT_ROOT"

        # Check for PR after completion
        if command -v gh &> /dev/null; then
            FINAL_PR=$(gh pr list --head "$FEATURE_BRANCH" --json url -q '.[0].url' 2>/dev/null || echo "")
        fi

        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║  ✓ SUCCESS - All tasks complete!"
        echo "║  Iterations: $i of $MAX"
        echo "║  Duration: Started at beginning, completed now"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Feature Implementation Summary:"
        echo "  Feature:        $FEATURE_NAME"
        echo "  Branch:         $FEATURE_BRANCH"
        echo "  Worktree:       $WORKTREE_PATH"
        if [ -n "$FINAL_PR" ]; then
            echo "  Pull Request:   $FINAL_PR"
        fi
        echo ""
        echo "Next steps:"
        if [ -n "$FINAL_PR" ]; then
            echo "  1. Review: $FINAL_PR"
            echo "  2. Merge:  git merge --ff-only $FEATURE_BRANCH"
        else
            echo "  1. View commits: git log $FEATURE_BRANCH --oneline"
            echo "  2. Merge:        git merge --ff-only $FEATURE_BRANCH"
        fi
        echo "  3. Cleanup:      git worktree remove $WORKTREE_PATH"
        echo ""
        exit 0
    fi

    # Safety check: if first worker and no PR exists after iteration, create it
    # (handles case where agent didn't create PR or concurrent workers)
    if [ $IS_FIRST -eq 1 ] && [ -z "$PR_URL" ]; then
        # Check again if PR exists (another worker might have created it)
        LATEST_PR=$(gh pr list --head "$FEATURE_BRANCH" --json url -q '.[0].url' 2>/dev/null || echo "")
        if [ -z "$LATEST_PR" ] && git log --oneline | head -1 >/dev/null 2>&1; then
            # Branch has commits but no PR exists, create it
            echo "[$(date '+%H:%M:%S')] Creating PR (first worker, agent didn't create one)..."
            gh pr create -B "$MAIN_BRANCH" -H "$FEATURE_BRANCH" --title "WIP: $FEATURE_NAME" --body "Track: $FEATURE_NAME. See PRD.md and TRACK.md for details." 2>/dev/null
            PR_URL=$(gh pr list --head "$FEATURE_BRANCH" --json url -q '.[0].url' 2>/dev/null || echo "")
            if [ -n "$PR_URL" ]; then
                echo "✓ PR created: $PR_URL"
            fi
        fi
    fi

    echo "[$(date '+%H:%M:%S')] Iteration $i complete. Remaining tasks: $INCOMPLETE_COUNT. Waiting ${SLEEP}s before next iteration..."
    sleep $SLEEP
done

# Cleanup on exit
cd "$PROJECT_ROOT"

# Check for PR
if command -v gh &> /dev/null; then
    FINAL_PR=$(gh pr list --head "$FEATURE_BRANCH" --json url -q '.[0].url' 2>/dev/null || echo "")
fi

# Count remaining incomplete tasks
REMAINING_INCOMPLETE=$(grep -c "^- \[ \]" "$WORKTREE_PATH/TRACK.md" 2>/dev/null || echo "?")

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Max iterations ($MAX) reached"
echo "║  Remaining incomplete tasks: $REMAINING_INCOMPLETE"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Work in Progress:"
echo "  Feature:        $FEATURE_NAME"
echo "  Branch:         $FEATURE_BRANCH"
echo "  Worktree:       $WORKTREE_PATH"
if [ -n "$FINAL_PR" ]; then
    echo "  Pull Request:   $FINAL_PR"
fi
echo ""
echo "Check progress:"
echo "  Remaining tasks: cat $WORKTREE_PATH/TRACK.md"
echo "  Recent commits:  git log $FEATURE_BRANCH -5 --oneline"
echo "  PR updates:      $([ -n "$FINAL_PR" ] && echo "$FINAL_PR" || echo "(no PR created yet)")"
echo ""
echo "To continue:"
echo "  ./ralph.sh 20  # Run 20 more iterations"
echo ""
echo "To inspect:"
echo "  cd $WORKTREE_PATH && cat TRACK.md  # See remaining tasks"
echo "  git log --oneline                  # View all commits"
echo ""
echo "To clean up when done:"
echo "  git worktree remove $WORKTREE_PATH"
echo ""
exit 1
