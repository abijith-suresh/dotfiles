---
name: git-checkpoint
description: create git stash checkpoints or roll back changes during development
---

# Git Checkpoint

Save and restore code state during exploratory agent sessions using git stash or temporary branch checkpoints.

## Usage

### Create a checkpoint
```bash
git stash create
```
Returns a commit hash representing the stash state if there are changes.

### View checkpoints
```bash
git stash list
```

### Restore a checkpoint
```bash
git stash apply <stash_ref>
```
