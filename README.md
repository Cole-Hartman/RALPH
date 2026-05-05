My take on [Ralph](https://www.aihero.dev/getting-started-with-ralph)

## [How It Works](https://excalidraw.com/#json=KZEjmk9uxUdacRM9wRD_Y,O8HQ4Zn0RMGgqVvaREmvZw)

<img width="7096" height="3090" alt="image" src="https://github.com/user-attachments/assets/36563abe-ff89-4663-89b9-425d994cb78d" />


## To Use
1. Ensure you're on a feature branch.
2. Set up Ralph state files in your branch:
    - Run the `/prd` skill to generate `.ralph/PRD.md`, `.ralph/TRACK.md`, `.ralph/progress.txt`, and `.ralph/prompt.md`
    - Or copy them manually into `.ralph/`
3. Run `./.ralph/ralph.sh`

Optional: Before merging, remove Ralph run files if you do not want them in the final PR diff:
- `git rm -r .ralph`
- `git commit -m "chore: remove Ralph run files"`
- `git push`

## File Structure

```
my-project/
  ├── src/
  │   └── ... (main codebase)
  │
  └── .ralph/
      ├── ralph.sh              # The bash loop runner
      ├── prompt.md             # Agent instructions
      ├── PRD.md                # Feature overview and goals
      ├── TRACK.md              # Implementation tasks and state
      └── progress.txt          # Iteration log and learnings
```

## Key Files

| File | Purpose |
|------|---------|
| `ralph.sh` | The bash loop runner that spawns fresh Claude instances for each iteration |
| `prompt.md` | Agent instructions: boundaries, state files, steps, and completion criteria |
| `PRD.md` | Feature overview, goals, scope, and technical considerations |
| `TRACK.md` | Ordered implementation tasks with acceptance criteria and completion state |
| `progress.txt` | Append-only log of iterations, patterns discovered, and learnings for future runs |
| `prd.md` | Guide for generating PRDs and breaking down features into Ralph tasks |

Task completion is tracked by markdown checkboxes in `TRACK.md`: `### [ ] T-001: Task title` becomes `### [x] T-001: Task title`.
