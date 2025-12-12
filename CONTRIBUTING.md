# Contributing to WoS Bot

## Fork Workflow Setup

This repository is a fork of `camoloqlo/wosbot`. Follow this workflow for contributing via pull requests.

### Remote Configuration

- **`origin`**: Your fork (`wahyutrip/wosbot`) - where you push your changes
- **`upstream`**: Original repository (`camoloqlo/wosbot`) - where you sync latest changes

### Standard Fork Workflow

#### 1. Keep Your Fork Up-to-Date

Before starting new work, sync with upstream:

```bash
# Fetch latest changes from upstream
git fetch upstream

# Switch to your local dev branch
git checkout dev

# Merge upstream changes into your local dev
git merge upstream/dev

# Push updated dev to your fork
git push origin dev
```

#### 2. Create a Feature Branch

Always create a new branch from the latest `dev` branch:

```bash
# Make sure dev is up-to-date (see step 1)
git checkout dev

# Create and switch to your feature branch
git checkout -b f/your-feature-name

# Or use the naming convention: f/dev-feature-name
git checkout -b f/dev-switch-profile
```

#### 3. Make Your Changes

- Write your code following project standards
- Commit with clear, descriptive messages
- Use conventional commit format: `feat:`, `fix:`, `refactor:`, `docs:`, etc.

```bash
git add .
git commit -m "feat: add switch profile feature"
```

#### 4. Push to Your Fork

Push your feature branch to your fork:

```bash
git push origin f/your-feature-name
```

#### 5. Create Pull Request

1. Go to GitHub: `https://github.com/camoloqlo/wosbot`
2. Click "New Pull Request"
3. Select:
   - **Base repository**: `camoloqlo/wosbot`
   - **Base branch**: `dev` (or `master` if appropriate)
   - **Head repository**: `wahyutrip/wosbot`
   - **Compare branch**: `f/your-feature-name`
4. Fill in PR description, link issues if applicable
5. Submit the PR

#### 6. Keep PR Up-to-Date

If upstream changes while your PR is open:

```bash
# Fetch upstream changes
git fetch upstream

# Switch to your feature branch
git checkout f/your-feature-name

# Rebase on latest upstream/dev (or merge if you prefer)
git rebase upstream/dev

# Force push to update your PR (only if rebased)
git push origin f/your-feature-name --force-with-lease
```

**Note**: Use `--force-with-lease` instead of `--force` for safety.

### Branch Naming Conventions

- Feature branches: `f/feature-name` or `f/dev-feature-name`
- Bug fixes: `fix/bug-description`
- Hotfixes: `hotfix/issue-description`

### Commit Message Format

Follow conventional commits:

- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code refactoring
- `docs:` - Documentation changes
- `test:` - Test additions/changes
- `chore:` - Build/tooling changes

Example:
```
feat: add switch profile feature with character selection UI

- Add CharacterSwitchHelper for profile switching logic
- Implement UI templates for character selection
- Update ProfileRepository with switch methods
```

### Current Setup

- **Your Fork**: `git@github.com-personal:wahyutrip/wosbot.git` (origin)
- **Original Repo**: `git@github.com:camoloqlo/wosbot.git` (upstream)
- **Git User**: `wahyutrip` / `admin@wahyutrip` (local config for this repo)
- **SSH Key**: `id_ed25519_personal` (via `github.com-personal` host alias)

### Quick Reference Commands

```bash
# View remotes
git remote -v

# Fetch from upstream
git fetch upstream

# Sync dev branch
git checkout dev
git merge upstream/dev
git push origin dev

# Create feature branch
git checkout -b f/feature-name

# Push feature branch
git push origin f/feature-name

# Update feature branch with upstream changes
git checkout f/feature-name
git rebase upstream/dev
git push origin f/feature-name --force-with-lease
```

### Best Practices

1. **Always branch from `dev`** (or appropriate base branch)
2. **Keep branches focused** - one feature per branch
3. **Sync frequently** - don't let your fork get too far behind
4. **Write clear commit messages** - helps reviewers understand changes
5. **Test before PR** - ensure your changes work as expected
6. **Respond to feedback** - be open to suggestions and improvements

