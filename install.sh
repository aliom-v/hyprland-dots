#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pacman_package_file="$repo_root/packages/pacman.txt"
aur_package_file="$repo_root/packages/aur.txt"
state_seed_root="$repo_root/state"

config_dirs=(
  hypr
  caelestia
  quickshell
  kitty
  foot
  fish
  fastfetch
  fcitx5
  uwsm
  btop
)

config_files=(
  starship.toml
)

picture_files=(
  "Wallpapers/1358147.png"
)

state_seed_files=(
  "caelestia/scheme.json"
)

dry_run=0
skip_deps=0
deps_only=0

usage() {
  cat <<'EOF'
Usage: bash ./install.sh [options]

Options:
  --dry-run    Print the actions without changing the system.
  --skip-deps  Skip package installation and only link dotfiles.
  --deps-only  Install packages only and skip linking dotfiles.
  -h, --help   Show this help message.
EOF
}

while (( $# > 0 )); do
  case "$1" in
    --dry-run)
      dry_run=1
      ;;
    --skip-deps)
      skip_deps=1
      ;;
    --deps-only)
      deps_only=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if (( skip_deps && deps_only )); then
  printf '%s\n' '--skip-deps and --deps-only cannot be used together' >&2
  exit 1
fi

if (( EUID == 0 )); then
  printf 'run this script as your regular user, not root\n' >&2
  exit 1
fi

backup_root="${HOME}/.dots-backups/$(date +%Y%m%d-%H%M%S)"
created_backup_dir=0

print_cmd() {
  printf '+'
  for arg in "$@"; do
    printf ' %q' "$arg"
  done
  printf '\n'
}

run() {
  if (( dry_run )); then
    print_cmd "$@"
    return 0
  fi

  "$@"
}

run_in_dir() {
  local dir="$1"
  shift

  if (( dry_run )); then
    printf '+ (cd %q &&' "$dir"
    for arg in "$@"; do
      printf ' %q' "$arg"
    done
    printf ')\n'
    return 0
  fi

  (
    cd "$dir"
    "$@"
  )
}

write_text_file() {
  local dst="$1"
  local content="$2"

  if (( dry_run )); then
    printf '+ write %q <= %q\n' "$dst" "$content"
    return 0
  fi

  printf '%s\n' "$content" > "$dst"
}

sudo_run() {
  if ! command -v sudo >/dev/null 2>&1; then
    printf 'sudo is required to install packages\n' >&2
    exit 1
  fi

  if (( dry_run )); then
    print_cmd sudo "$@"
    return 0
  fi

  sudo "$@"
}

load_package_list() {
  local file="$1"
  local -n out_ref="$2"

  if [[ ! -f "$file" ]]; then
    printf 'missing package list: %s\n' "$file" >&2
    exit 1
  fi

  mapfile -t out_ref < <(sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$file")
}

ensure_arch() {
  if ! command -v pacman >/dev/null 2>&1; then
    printf 'dependency installation currently supports Arch-based systems only\n' >&2
    exit 1
  fi
}

ensure_yay() {
  local tmpdir

  if command -v yay >/dev/null 2>&1; then
    return 0
  fi

  ensure_arch
  printf 'bootstrapping yay\n'
  sudo_run pacman -Syu --needed --noconfirm base-devel git

  if (( dry_run )); then
    tmpdir="/tmp/yay-bootstrap"
  else
    tmpdir="$(mktemp -d)"
  fi

  run git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  run_in_dir "$tmpdir/yay" makepkg -si --noconfirm

  if (( ! dry_run )); then
    rm -rf "$tmpdir"
  fi
}

install_dependencies() {
  local pacman_packages=()
  local aur_packages=()

  ensure_arch
  load_package_list "$pacman_package_file" pacman_packages
  load_package_list "$aur_package_file" aur_packages

  if (( ${#pacman_packages[@]} > 0 )); then
    printf 'installing official packages\n'
    sudo_run pacman -Syu --needed --noconfirm "${pacman_packages[@]}"
  fi

  if (( ${#aur_packages[@]} > 0 )); then
    ensure_yay
    printf 'installing AUR packages\n'
    run yay -S --needed --noconfirm --answerdiff None --answerclean None "${aur_packages[@]}"
  fi
}

ensure_backup_dir() {
  if (( created_backup_dir == 0 )); then
    run mkdir -p "$backup_root"
    created_backup_dir=1
  fi
}

backup_and_link() {
  local src="$1"
  local dst="$2"
  local resolved_src resolved_dst backup_path

  resolved_src="$(readlink -f "$src")"

  if [[ -L "$dst" ]]; then
    resolved_dst="$(readlink -f "$dst" || true)"
    if [[ "$resolved_dst" == "$resolved_src" ]]; then
      printf 'skip  %s\n' "$dst"
      return 0
    fi
  fi

  if [[ -e "$dst" || -L "$dst" ]]; then
    ensure_backup_dir
    backup_path="$backup_root/${dst#"$HOME"/}"
    run mkdir -p "$(dirname "$backup_path")"
    run mv "$dst" "$backup_path"
    printf 'backup %s -> %s\n' "$dst" "$backup_path"
  fi

  run mkdir -p "$(dirname "$dst")"
  run ln -sfn "$src" "$dst"
  printf 'link  %s -> %s\n' "$dst" "$src"
}

seed_file_if_missing() {
  local src="$1"
  local dst="$2"

  if [[ -e "$dst" || -L "$dst" ]]; then
    printf 'skip  %s\n' "$dst"
    return 0
  fi

  run mkdir -p "$(dirname "$dst")"
  run cp "$src" "$dst"
  printf 'seed  %s <- %s\n' "$dst" "$src"
}

seed_wallpaper_state() {
  local dst="$HOME/.local/state/caelestia/wallpaper/path.txt"
  local wallpaper_path="$HOME/Pictures/${picture_files[0]}"
  local existing=""

  if [[ -f "$dst" ]]; then
    existing="$(<"$dst")"
  fi

  if [[ -n "$existing" && -e "$existing" ]]; then
    printf 'skip  %s\n' "$dst"
    return 0
  fi

  run mkdir -p "$(dirname "$dst")"
  write_text_file "$dst" "$wallpaper_path"
  printf 'seed  %s <- %s\n' "$dst" "$wallpaper_path"
}

seed_runtime_state() {
  local item

  for item in "${state_seed_files[@]}"; do
    seed_file_if_missing "$state_seed_root/$item" "$HOME/.local/state/$item"
  done

  seed_wallpaper_state
}

link_dotfiles() {
  local item

  for item in "${config_dirs[@]}"; do
    backup_and_link "$repo_root/config/$item" "$HOME/.config/$item"
  done

  for item in "${config_files[@]}"; do
    backup_and_link "$repo_root/config/$item" "$HOME/.config/$item"
  done

  for item in "${picture_files[@]}"; do
    backup_and_link "$repo_root/pictures/$item" "$HOME/Pictures/$item"
  done
}

if (( ! skip_deps )); then
  install_dependencies
fi

if (( ! deps_only )); then
  link_dotfiles
  seed_runtime_state
fi

if (( dry_run )); then
  printf 'dry run complete\n'
else
  printf 'install complete\n'
fi
