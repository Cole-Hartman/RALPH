My take on [Ralph](https://www.aihero.dev/getting-started-with-ralph)

## [How It Works](https://excalidraw.com/#json=uAOLfwHkgc3OpG_ODOJe3,aCVSy0iwvnp81eU9KYP0mg)

<img width="10000" alt="image" src="https://github.com/user-attachments/assets/827702c4-3420-472b-ab60-4b5b80ddbdfa" />

## To Use
1. Create and enter a feature worktree manually:
    - `git worktree add -b feature/<your-feature> .worktrees/feature-<your-feature> main`
    - `cd .worktrees/feature-<your-feature>`
2. Copy Ralph into the worktree:
    - `mkdir -p .ralph`
    - `cp /path/to/RALPH/ralph.sh .ralph/ralph.sh`
    - `chmod +x .ralph/ralph.sh`
3. Tell the agent what you want to build and generate track with `/prd` skill:
    - `.ralph/PRD.md` - What the feature is
    - `.ralph/TRACK.md` - Steps to building it
    - `.ralph/progress.txt` - Shared agent state
4. Run `./.ralph/ralph.sh`

5. Or run in parallel from separate worktrees:
    - `(cd .worktrees/feature-auth-feature && ./.ralph/ralph.sh) &`
    - `(cd .worktrees/feature-dashboard-redesign && ./.ralph/ralph.sh) &`

6. Before merging, remove Ralph run files if you do not want them in the final PR diff:
    - `git rm -r .ralph`
    - `git commit -m "chore: remove Ralph run files"`
    - `git push`

## File Structure
```
my-project/
  ├── README.md
  ├── src/
  │   └── ... (main codebase)
  │
  ├── .worktrees/
  │   ├── feature-auth-feature/        # isolated workspace + branch
  │   │   ├── src/
  │   │   │   └── ...
  │   │   └── .ralph/
  │   │       ├── ralph.sh             # runner for this worktree
  │   │       ├── PRD.md               # what the feature is
  │   │       ├── TRACK.md             # tasks and completion state
  │   │       └── progress.txt         # shared agent state
  │   │
  │   └── feature-dashboard-redesign/
  │       ├── src/
  │       │   └── ...
  │       └── .ralph/
  │           ├── ralph.sh
  │           ├── PRD.md
  │           ├── TRACK.md
  │           └── progress.txt
  │
  └── .git/refs/heads/
      ├── main
      ├── feature/auth-feature
      └── feature/dashboard-redesign
```

---

**Each track**
- Gets its own manually-created worktree at `.worktrees/feature-xxx/`
- Gets its own git branch `feature/xxx`
- Gets its own `.ralph/` state directory inside the worktree
- Gets its own PR on GitHub
- Runs independently from others
- Uses task headings like `### [ ] T-001: Add priority field`
- Marks complete tasks by changing `### [ ]` to `### [x]`
- Can remove `.ralph/` before merge if you do not want Ralph files in the final PR diff

