My take on [Ralph](https://www.aihero.dev/getting-started-with-ralph)

## Model

This version assumes you create the feature worktree yourself. Ralph then runs
entirely inside that worktree, so the agent does not need to understand or manage
worktrees.

```text
main checkout
  src/
  ...

.worktrees/
  feature-auth/
    src/
    .ralph/
      ralph.sh
      PRD.md
      TRACK.md
      progress.txt
```

Ralph state lives in `.ralph/` while the run is active. The agent can read and
write progress normally because the state files are inside the same checkout as
the code it is editing.

## To Use

1. Create a feature worktree manually.

```bash
git worktree add -b feature/auth .worktrees/feature-auth main
cd .worktrees/feature-auth
```

2. Copy Ralph into the worktree.

```bash
mkdir -p .ralph
cp /path/to/RALPH/ralph.sh .ralph/ralph.sh
chmod +x .ralph/ralph.sh
```

3. Run the `/prd` skill from inside the worktree.

It creates:

```text
.ralph/PRD.md
.ralph/TRACK.md
.ralph/progress.txt
```

4. Run Ralph.

```bash
./.ralph/ralph.sh
```

Optional arguments:

```bash
./.ralph/ralph.sh 20      # 20 iterations
./.ralph/ralph.sh 20 5    # 20 iterations, 5s delay
```

5. Before merging, remove Ralph run files if you do not want them in the final
PR diff.

```bash
git rm -r .ralph
git commit -m "chore: remove Ralph run files"
git push
```

If you squash merge, main receives the implementation without the temporary
Ralph state files.

## What Ralph Does

Each iteration:

1. Reads `.ralph/PRD.md`, `.ralph/TRACK.md`, and `.ralph/progress.txt`.
2. Finds the first incomplete task heading in `.ralph/TRACK.md`.
3. Implements exactly one task.
4. Runs the relevant checks.
5. If checks pass, marks that task heading complete.
6. Appends learnings to `.ralph/progress.txt`.
7. Commits the work.
8. Pushes the branch and creates a PR if one does not exist.

Task headings must use this format:

```markdown
### [ ] T-001: Add priority field to database
```

Ralph marks completion by changing the heading to:

```markdown
### [x] T-001: Add priority field to database
```

Acceptance criteria should be normal bullets, not checkbox bullets. This keeps
task completion separate from acceptance criteria.

## Parallel Runs

Create one worktree per feature and run Ralph inside each one:

```bash
git worktree add -b feature/auth .worktrees/feature-auth main
git worktree add -b feature/dashboard .worktrees/feature-dashboard main

(cd .worktrees/feature-auth && ./.ralph/ralph.sh) &
(cd .worktrees/feature-dashboard && ./.ralph/ralph.sh) &
wait
```

Each worktree has its own `.ralph/` directory, branch, commits, and PR.

## Local-Only State Option

The default flow allows Ralph files to be committed temporarily and removed
before merge. If you prefer Ralph state to never enter git history, add this to
the worktree's local exclude file instead:

```bash
printf '\n.ralph/\n' >> "$(git rev-parse --git-path info/exclude)"
```

Then `.ralph/` remains local-only. The tradeoff is that the PR history will not
show the PRD, track, or progress log.
