# Rollback Procedures

This document describes how to recover from failed configuration changes in your nix-darwin system. There are three primary rollback methods, each suited for different scenarios.

---

## Quick Reference

| Scenario | Method | Command |
|----------|--------|---------|
| Just applied a bad change | Generation Rollback | `darwin-rebuild rollback` |
| Need to pick a specific generation | Selective Generation | `darwin-rebuild switch --rollback --generation N` |
| System won't boot | Boot Menu | Hold Option at startup |
| Want to revert code changes | Git-Based | `git revert <commit>` + rebuild |

---

## Method 1: Generation Rollback

The fastest way to undo a recent configuration change. nix-darwin keeps a history of all system configurations (called "generations").

### List Available Generations

View all previous system configurations:

```bash
darwin-rebuild --list-generations
```

**Example output:**
```
  1   2024-01-15 10:23:45
  2   2024-01-16 14:30:12
  3   2024-01-17 09:15:33   (current)
```

The current generation is marked with `(current)`.

### Rollback to Previous Generation

Revert to the immediately previous generation:

```bash
darwin-rebuild rollback
```

This command:
- Switches to the previous generation
- Updates system settings immediately
- Does NOT require sudo (uses existing activation)
- Takes effect without a reboot

**What gets rolled back:**
- System settings (Dock, Finder, defaults)
- Installed packages
- Home Manager configuration
- Shell environment
- Application preferences

**What does NOT get rolled back:**
- User data and files
- Homebrew cask applications (they persist)
- Git repository state
- Secrets in `~/.config/sops/`

### Rollback to Specific Generation

If you need to go back further than one generation:

```bash
# First, list generations to find the number
darwin-rebuild --list-generations

# Then switch to that generation
darwin-rebuild switch --rollback --generation 5
```

Replace `5` with the generation number you want.

### Verify Rollback Success

After rolling back, verify the system state:

```bash
# Check current generation
darwin-rebuild --list-generations | grep current

# Verify packages are correct
which ripgrep fd bat

# Check system settings
defaults read com.apple.dock autohide
```

---

## Method 2: Boot Menu Rollback

Use this method when the system is unstable or won't boot properly after a configuration change.

### Access Boot Menu

1. **Restart your Mac**
2. **Immediately hold the Option (⌥) key** during startup
3. **Keep holding** until you see the boot menu

### Select Previous Generation

The boot menu will show:
- **Macintosh HD** - Current generation
- **Macintosh HD (1)** - Previous generation
- **Macintosh HD (2)** - Two generations back
- etc.

**To boot into a previous generation:**
1. Use arrow keys to select the generation
2. Press Enter to boot

### Make Rollback Permanent

After booting into a previous generation:

```bash
# The system is now running the old configuration
# To make this permanent (set as default):
darwin-rebuild switch --rollback --generation $(darwin-rebuild --list-generations | grep current | awk '{print $1}')
```

Or simply rebuild from your git repository (see Method 3).

### When to Use Boot Menu Rollback

- System is unstable after configuration change
- Can't log in due to authentication issues
- Display settings are broken
- Keyboard/input not working properly
- Need to access system before full boot

---

## Method 3: Git-Based Rollback

The most precise method - revert specific code changes and rebuild. This is the recommended approach for production systems.

### View Recent Changes

```bash
cd /Users/lu/.config/nix

# View commit history
git log --oneline -10

# View changes in a specific commit
git show <commit-hash>

# View current changes (not yet committed)
git diff
```

### Revert a Specific Commit

To undo a specific commit while preserving history:

```bash
cd /Users/lu/.config/nix

# Find the commit to revert
git log --oneline

# Revert it (creates a new commit that undoes the changes)
git revert <commit-hash>

# Rebuild with the reverted configuration
darwin-rebuild switch --flake .#lu-mbp
```

**Example:**
```bash
# Revert the most recent commit
git revert HEAD

# Revert a specific commit
git revert abc123f

# Revert multiple commits
git revert abc123f..def456g
```

### Reset to a Previous Commit

**⚠️ WARNING:** This discards all commits after the target. Only use if you're certain.

```bash
cd /Users/lu/.config/nix

# View history to find the good commit
git log --oneline

# Reset to that commit (keeps changes as uncommitted)
git reset <commit-hash>

# Or reset and discard all changes
git reset --hard <commit-hash>

# Rebuild
darwin-rebuild switch --flake .#lu-mbp
```

### Rollback Uncommitted Changes

If you've made changes but haven't committed them:

```bash
cd /Users/lu/.config/nix

# Discard all uncommitted changes
git checkout .

# Or discard changes to a specific file
git checkout -- path/to/file.nix

# Rebuild
darwin-rebuild switch --flake .#lu-mbp
```

### Test Before Committing

Always test configuration changes before committing:

```bash
# Dry-run build (doesn't apply changes)
darwin-rebuild dry-build --flake .#lu-mbp

# Build without switching (creates ./result symlink)
darwin-rebuild build --flake .#lu-mbp

# If successful, apply
darwin-rebuild switch --flake .#lu-mbp

# If everything works, commit
git add .
git commit -m "Add feature X"
git push
```

---

## Recovery Scenarios

### Scenario 1: "I just ran darwin-rebuild and something broke"

**Solution:** Generation rollback (fastest)

```bash
darwin-rebuild rollback
```

### Scenario 2: "I made several changes and need to go back 3 versions"

**Solution:** Selective generation rollback

```bash
# List generations
darwin-rebuild --list-generations

# Switch to specific generation
darwin-rebuild switch --rollback --generation 5
```

### Scenario 3: "System won't boot after configuration change"

**Solution:** Boot menu rollback

1. Restart and hold Option key
2. Select previous generation from boot menu
3. After booting, run: `darwin-rebuild rollback`

### Scenario 4: "I want to undo a specific feature I added yesterday"

**Solution:** Git-based rollback

```bash
cd /Users/lu/.config/nix
git log --oneline --since="2 days ago"
git revert <commit-hash>
darwin-rebuild switch --flake .#lu-mbp
```

### Scenario 5: "I'm testing changes and want to easily revert"

**Solution:** Use a git branch

```bash
cd /Users/lu/.config/nix

# Create a test branch
git checkout -b test-feature

# Make changes and test
# ... edit files ...
darwin-rebuild switch --flake .#lu-mbp

# If it works, merge
git checkout main
git merge test-feature

# If it doesn't work, just switch back
git checkout main
darwin-rebuild switch --flake .#lu-mbp
```

### Scenario 6: "Build fails with evaluation error"

**Solution:** Check syntax and revert

```bash
cd /Users/lu/.config/nix

# Check what changed
git diff

# Validate syntax
nix flake check

# If broken, revert uncommitted changes
git checkout .

# Or revert last commit
git revert HEAD

# Rebuild
darwin-rebuild switch --flake .#lu-mbp
```

---

## Emergency Recovery

### System Completely Broken

If the system is severely broken and normal rollback doesn't work:

1. **Boot into Recovery Mode:**
   - Restart and hold Command (⌘) + R
   - Wait for Recovery Mode to load

2. **Access Terminal:**
   - From the menu bar: Utilities → Terminal

3. **Mount your system volume:**
   ```bash
   diskutil list
   # Find your main volume (usually disk1s1 or disk3s1)
   diskutil mount /dev/disk1s1
   ```

4. **Rollback using nix-store:**
   ```bash
   # List available generations
   ls -la /Volumes/Macintosh\ HD/nix/var/nix/profiles/system-*-link

   # Activate a previous generation
   /Volumes/Macintosh\ HD/nix/var/nix/profiles/system-42-link/activate
   ```

5. **Reboot:**
   ```bash
   reboot
   ```

### Nix Daemon Won't Start

If Determinate Nix daemon fails to start:

```bash
# Check daemon status
sudo launchctl list | grep determinate

# Restart daemon
sudo launchctl kickstart -k system/systems.determinate.nix-daemon

# View daemon logs
sudo log show --predicate 'process == "nix-daemon"' --last 5m
```

### Home Manager Activation Fails

If home-manager activation fails during rebuild:

```bash
# Skip home-manager activation temporarily
darwin-rebuild switch --flake .#lu-mbp --skip-home-manager

# Then fix home.nix and try again
darwin-rebuild switch --flake .#lu-mbp
```

---

## Prevention Best Practices

### 1. Always Test Before Committing

```bash
# Build without applying
darwin-rebuild build --flake .#lu-mbp

# Check for errors
nix flake check

# If successful, then apply
darwin-rebuild switch --flake .#lu-mbp
```

### 2. Use Descriptive Commit Messages

```bash
git commit -m "Add ripgrep and fd to CLI tools"
# NOT: git commit -m "update"
```

This makes it easier to identify what to revert.

### 3. Commit Frequently

Small, focused commits are easier to revert than large ones:

```bash
# Good: Multiple small commits
git commit -m "Add ripgrep package"
git commit -m "Configure zsh aliases"
git commit -m "Update Dock settings"

# Bad: One large commit
git commit -m "Update everything"
```

### 4. Keep Generations Clean

Periodically clean old generations to save disk space:

```bash
# Delete generations older than 30 days
nix-collect-garbage --delete-older-than 30d

# Or delete all but the last 5 generations
nix-collect-garbage --delete-generations +5
```

**⚠️ WARNING:** After garbage collection, you can't rollback to deleted generations.

### 5. Backup Configuration Repository

Your configuration is in git, but also backup the repository:

```bash
# Push to remote regularly
cd /Users/lu/.config/nix
git push origin main

# Or create a backup
tar -czf ~/nix-config-backup-$(date +%Y%m%d).tar.gz ~/.config/nix
```

---

## Troubleshooting Rollback Issues

### "No previous generation available"

**Cause:** This is the first generation or old generations were garbage collected.

**Solution:** Use git-based rollback instead:
```bash
cd /Users/lu/.config/nix
git log --oneline
git revert <commit-hash>
darwin-rebuild switch --flake .#lu-mbp
```

### "Permission denied" during rollback

**Cause:** Insufficient permissions.

**Solution:** Use sudo for system changes:
```bash
sudo darwin-rebuild rollback
```

### Rollback succeeds but issue persists

**Cause:** The issue might be in user data, not configuration.

**Solution:** Check for:
- Corrupted cache files: `rm -rf ~/.cache/*`
- Application preferences: `defaults delete com.app.name`
- Homebrew state: `brew cleanup`

### "Flake evaluation failed" after rollback

**Cause:** Git repository state doesn't match generation.

**Solution:**
```bash
cd /Users/lu/.config/nix

# Ensure git is clean
git status

# Stash any uncommitted changes
git stash

# Try rollback again
darwin-rebuild rollback
```

---

## Additional Resources

- **nix-darwin manual:** https://daiderd.com/nix-darwin/manual/
- **Nix generations:** https://nixos.org/manual/nix/stable/package-management/profiles.html
- **Git revert guide:** https://git-scm.com/docs/git-revert
- **Determinate Nix docs:** https://docs.determinate.systems/

---

## Summary

**Three rollback methods:**

1. **Generation Rollback** - Fast, for recent changes
   - `darwin-rebuild rollback`

2. **Boot Menu** - When system won't boot properly
   - Hold Option key at startup

3. **Git-Based** - Precise, for specific changes
   - `git revert <commit>` + rebuild

**Always test before committing. Small commits are easier to revert.**

For questions or issues, refer to the main [README.md](../README.md) or [BOOTSTRAP.md](./BOOTSTRAP.md).
