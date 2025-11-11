# lu's nix-darwin configuration

This repository contains my macOS configuration built with nix-darwin, home-manager, and Determinate Nix. Everything is declarative: the same `darwin-rebuild switch --flake ~/.config/nix#lu-mbp` command applies macOS defaults, Homebrew apps, CLI tooling, dotfiles, and Nix daemon settings.

## Prerequisites

- A macOS host with Xcode Command Line Tools.
- Determinate Nix (handles the daemon and provides flakes out of the box):

  ```bash
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  ```

## Cloning and applying the configuration

```bash
git clone https://github.com/lu-mbp/nix-config ~/.config/nix
cd ~/.config/nix
darwin-rebuild switch --flake .#lu-mbp
```

`darwin-rebuild` does not need `sudo` because Determinate already manages the daemon. Re-run the same command after making any change.

## Repository layout

```
~/.config/nix/
├── flake.nix
├── hosts/
│   └── lu-mbp/default.nix    # Host composition (nix-darwin + HM + nix-homebrew)
├── modules/
│   ├── system.nix            # nix-darwin host settings + Determinate config
│   ├── homebrew.nix          # Declarative Homebrew/MAS apps
│   ├── darwin/               # system.defaults, Dock, app prefs, Touch ID
│   └── home/                 # home-manager modules (packages, shell, git, ssh…)
└── users/
    └── lu/home.nix          # User entry point importing modules/home/*.nix
```

Key modules:

- `modules/system.nix` – imports macOS preference modules and sets Determinate `determinate-nix.customSettings`.
- `modules/homebrew.nix` – Homebrew casks, brews, and App Store apps.
- `modules/home/packages.nix` – All CLI tooling and fonts.
- `modules/home/shell.nix`, `git.nix`, `ssh.nix`, etc. – Individual concerns for home-manager.

## SSH bootstrap helper

`home-manager` now generates an Ed25519 key automatically on the first rebuild and reminds you to add it to the macOS Keychain. Run the helper below only to connect that key to GitHub (auth + uploading auth/signing keys):

```bash
~/bin/bootstrap-ssh.sh
```

The script (installed by `modules/home/ssh.nix`) performs a browser-based `gh auth login` if needed and registers both auth + signing keys with GitHub. It assumes the key already exists from the `home.activation` hook.

## Daily commands

- Update inputs: `nix flake update` followed by `darwin-rebuild switch --flake .#lu-mbp`.
- Test changes without applying: `darwin-rebuild dry-build --flake .#lu-mbp`.
- Roll back: `darwin-rebuild switch --rollback`.

All configuration lives here—avoid imperative `nix-env`/`nix profile`/manual Homebrew installs. Instead, edit the appropriate module and rebuild.
