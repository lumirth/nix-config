# lu's nix-darwin configuration

This repo is a flakes-first macOS configuration powered by Determinate Nix, nix-darwin, home-manager, nix-homebrew, and sops-nix. Flake composition is handled by **flake-parts**, with reusable overlays, devshells, and CI checks defined in `flake/`.

## Prerequisites

- macOS with Xcode Command Line Tools installed.
- Determinate Nix (installs the daemon + flakes support):

  ```bash
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  ```

- Infisical CLI (Homebrew formula `infisical/tap/infisical`) to hydrate the Age private key.

## Getting started

```bash
git clone https://github.com/lu-mbp/nix-config ~/.config/nix
cd ~/.config/nix

# Optional but recommended: enter the devshell (nix, sops, age, nixd, statix, etc.)
nix develop

# 1) Hydrate the Age private key from Infisical (see “Secrets” below)
./bin/infisical-bootstrap-sops

# 2) Apply the unified system + home configuration
sudo darwin-rebuild switch --flake .#lu-mbp

# Optional one-liner (after secrets are set up)
./bin/infisical-bootstrap-sops \\
  && sudo darwin-rebuild switch --flake .#lu-mbp \\
  && ~/bin/bootstrap-ssh.sh
```

Both commands are declarative; the system tier still needs `sudo darwin-rebuild` because macOS activation scripts touch privileged paths, but Determinate manages the daemon configuration automatically.

## Repository layout

```
~/.config/nix
├── flake.nix                # flake-parts entrypoint
├── flake/                   # per-system packages, devshell, checks, darwin/home outputs
├── overlays/                # custom overlays (e.g., claude-code-acp)
├── lib/                     # helpers (future home for host builders/utilities)
├── hosts/
│   └── lu-mbp/
│       ├── system/          # nix-darwin host module (system tier)
│       └── home/            # host-scoped home-manager entrypoint
├── modules/
│   ├── system.nix           # nix-darwin base config + Determinate settings
│   ├── darwin/              # macOS defaults, Dock, Touch ID, etc.
│   └── home/                # reusable home-manager modules (packages, shell, git, ssh…)
├── secrets/                 # sops-encrypted blobs (Rectangle Pro licenses, etc.)
└── bin/infisical-bootstrap-sops
```

### Key modules

- `modules/system.nix` – system defaults + Determinate Nix wiring (`nix.enable = false`, `determinate-nix.customSettings` manages `/etc/nix/nix.custom.conf`).
- `modules/darwin/*` – Finder/Dock defaults, app preferences, Touch ID, etc.
- `modules/home/*` – granular HM modules (packages, shell, git, ssh, fonts, Rectangle Pro secrets, sops glue).
- `overlays/default.nix` – custom packages exposed as `pkgs.<name>` (currently `claude-code-acp`).

## Secrets workflow (sops-nix + Infisical)

1. Secrets live encrypted under `secrets/`, tracked in git.
2. The Age private key stays out of repo. Store it in Infisical (`SOPS_AGE_KEY` in workspace `f3d4ff0d-b521-4f8a-bd99-d110e70714ac`, env `prod`, path `/macos`). Bootstrap manually **before** building (the devshell prints a warning until the key exists):

   ```bash
   ./bin/infisical-bootstrap-sops
   # optional overrides:
   # INFISICAL_SECRET_NAME, INFISICAL_ENVIRONMENT, INFISICAL_PATH, INFISICAL_PROJECT_ID
   ```

   The script runs `infisical secrets get … --plain --silent` and writes `~/.config/sops/age/keys.txt`.

3. nix-darwin + Home Manager (via `modules/home/sops.nix`) expect that key for decrypting secrets declared in `modules/home/apps/rectangle-pro.nix`, etc.

4. SSH keys are declaratively managed the same way. Encrypt your long-lived keypair under `secrets/ssh/` (private + public) so every host gets the same identity:

   ```bash
   mkdir -p secrets/ssh
   nix shell nixpkgs#sops -c sops secrets/ssh/id_ed25519       # paste your private key (or generate with ssh-keygen first)
   nix shell nixpkgs#sops -c sops secrets/ssh/id_ed25519.pub   # paste the matching .pub
   git add secrets/ssh
   ```

   During `sudo darwin-rebuild switch --flake .#lu-mbp`, sops-nix writes the decrypted files to `~/.ssh/` and the helper script `~/bin/bootstrap-ssh.sh` can upload them to GitHub. The build fails early if either encrypted file is missing.

5. To edit any secret, use `sops` directly so encryption remains intact:

   ```bash
   nix shell nixpkgs#sops -c sops secrets/rectangle-pro/580977.padl
   ```

**Quirk:** sops-nix cannot call Infisical during evaluation. Hydrate the Age key (step 2) before running `sudo darwin-rebuild switch --flake .#lu-mbp` on a new host/CI runner. `.infisical.json` remains git-ignored.

## Validation, formatting, and CI

- `nix fmt` – runs `nixpkgs-fmt` via flake-parts `formatter`.
- `nix flake check` – builds `darwinConfigurations.lu-mbp`, runs fmt check, and ensures secrets stay encrypted.
- GitHub Actions can run:

  ```bash
  nix run determinate.systems/flake-checker-action
  nix build .#darwinConfigurations.lu-mbp.system --no-link
  ```

## Daily commands

- Apply system + home changes: `sudo darwin-rebuild switch --flake .#lu-mbp`
- Preview changes: `darwin-rebuild dry-build --flake .#lu-mbp`
- Reformat/check: `nix fmt`, `nix flake check`
- Update inputs: `nix flake update`
- Roll back: `darwin-rebuild switch --rollback`

Everything is declarative—avoid `nix-env`, `nix profile install`, or ad-hoc `defaults write`. GUI apps go through nix-homebrew + casks, CLI tools go through `modules/home/packages.nix`, and secrets stay in `secrets/` encrypted by sops-nix.
