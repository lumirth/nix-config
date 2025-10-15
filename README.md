This is my nix config. Nix is a colossal pain in the ass, and only barely worth the trouble. But barely worth the trouble is still worth it, so here we are.

```zsh
# install determinate nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# pull config from github
git clone https://github.com/lu-mbp/nix-config.git ~/.config/nix

# activate config
sudo nix run github:LnL7/nix-darwin/master#darwin-rebuild \
  -- switch \
  --flake ~/.config/nix#lu-mbp

# add ssh to keychain
ssh-add --apple-use-keychain /Users/lu/.ssh/id_ed25519

# for devenv
echo "trusted-users = root $(whoami)" | sudo tee -a /etc/nix/nix.custom.conf

```
