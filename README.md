My take on [Ralph](https://www.aihero.dev/getting-started-with-ralph)

## [How It Works](https://excalidraw.com/#json=uAOLfwHkgc3OpG_ODOJe3,aCVSy0iwvnp81eU9KYP0mg)

<img width="10000" alt="image" src="https://github.com/user-attachments/assets/827702c4-3420-472b-ab60-4b5b80ddbdfa" />

## To Use
1. Tell the agent what you want to build
2. Generate track with `/prd` skill:
    - `tracks/<your-feature>/PRD.md` - What the feature is
    - `tracks/<your-feature>/TRACK.md` - Steps to building it
    - `tracks/<your-feature>/progress.txt` - Shared agent state
3. Run `ralph.sh tracks/<your-feature>/`

4. Or run in parallel `./ralph.sh tracks/<your-feature>/ & ./ralph.sh tracks/<your-feature2>/`

## File Structure
```
my-project/
  ├── README.md
  ├── src/
  │   └── ... (main codebase)
  │
  ├── tracks/
  │   ├── auth-feature/
  │   │   ├── PRD.md
  │   │   ├── TRACK.md
  │   │   └── progress.txt
  │   │
  │   └── dashboard-redesign/
  │       ├── PRD.md
  │       ├── TRACK.md
  │       └── progress.txt
  │
  ├── .worktrees/feature/
  │   ├── feature-auth-feature/       # Isolated workspace + branch
  │   └── feature-dashboard-redesign/
  │
  ├── ralph.sh
  └── .git/refs/heads/
      ├── main
      ├── feature/feature-auth-feature
      └── feature/feature-dashboard-redesign
```

---

**Each track**
- Gets its own worktree at .worktrees/feature/feature-xxx/
- Gets its own git branch feature/feature-xxx
- Gets its own PR on GitHub
- Runs independently from others


