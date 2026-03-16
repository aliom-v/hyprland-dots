# hyprland dots

Current desktop setup packaged as a personal dotfiles repo.

Included:
- Hyprland
- Caelestia + Quickshell
- Kitty and Foot
- Fish + Starship
- Fastfetch
- Fcitx5
- UWSM
- btop
- Current wallpaper

Layout:
- `config/` maps to `~/.config/`
- `pictures/` maps to `~/Pictures/`

Install:

```bash
bash ./install.sh --dry-run
bash ./install.sh
```

On Arch-based systems the installer now:
- installs packages from `packages/pacman.txt`
- bootstraps `yay` if needed
- installs AUR packages from `packages/aur.txt`
- links the dotfiles into `~/.config` and `~/Pictures`

Useful flags:
- `--skip-deps` only links dotfiles
- `--deps-only` only installs packages

The installer covers shell/runtime dependencies and the apps configured in this repo.
Personal app choices such as `brave`, `codium`, and `nemo` are still left to you.

What this repo manages:
- `~/.config/hypr`
- `~/.config/caelestia`
- `~/.config/quickshell`
- `~/.config/kitty`
- `~/.config/foot`
- `~/.config/fish`
- `~/.config/fastfetch`
- `~/.config/fcitx5`
- `~/.config/uwsm`
- `~/.config/btop`
- `~/.config/starship.toml`
- `~/Pictures/Wallpapers/1358147.png`

What was intentionally left out:
- `fish_variables`
- `fcitx5/conf/cached_layouts`
- app data, caches, and runtime state
- unused configs such as Waybar

Notes:
- `install.sh` moves existing managed targets into `~/.dots-backups/<timestamp>/` before linking.
- This repo is a snapshot of the current machine state. If you change live config later, sync those changes back into this repo.
- Machine-specific overrides belong in the gitignored files `~/.config/caelestia/hypr-user.local.conf` and `~/.config/caelestia/hypr-execs.local.conf`.
