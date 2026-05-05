My take on [Ralph](https://www.aihero.dev/getting-started-with-ralph)

## To Use
1. Tell the agent what you want to build
2. Generate track with `/prd` skill:
    - `tracks/<your-feature>/PRD.md`
    - `tracks/<your-feature>/TRACK.md`
    - `tracks/<your-feature>/progress.txt`
3. Run `ralph.sh tracks/<your-feature>/`

4. Or run in parallel `./ralph.sh tracks/<your-feature>/ & ./ralph.sh tracks/<your-feature2>/`

---

**Each track**
- Gets its own worktree at .worktrees/feature/feature-xxx/
- Gets its own git branch feature/feature-xxx
- Gets its own PR on GitHub
- Runs independently from others

## [How It Works](https://excalidraw.com/#json=uAOLfwHkgc3OpG_ODOJe3,aCVSy0iwvnp81eU9KYP0mg)

<img width="10000" alt="image" src="https://github.com/user-attachments/assets/827702c4-3420-472b-ab60-4b5b80ddbdfa" />


