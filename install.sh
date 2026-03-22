#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pacman_package_file="$repo_root/packages/pacman.txt"
aur_package_file="$repo_root/packages/aur.txt"
state_seed_root="$repo_root/state"
install_state_dir="${HOME}/.local/state/hyprland-dots"
install_state_file="$install_state_dir/last-install.sh"
backup_parent="${HOME}/.dots-backups"

config_dirs=(
  hypr
  caelestia
  quickshell
  kitty
  foot
  fuzzel
  fish
  fastfetch
  menus
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
uninstall=0
linked_targets=()
created_seed_paths=()

usage() {
  cat <<'EOF'
Usage: bash ./install.sh [options]

Options:
  --dry-run    Print the actions without changing the system.
  --skip-deps  Skip package installation and only link dotfiles.
  --deps-only  Install packages only and skip linking dotfiles.
  --uninstall  Restore the previous dotfiles state from the latest install.
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
    --uninstall)
      uninstall=1
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

if (( uninstall && (skip_deps || deps_only) )); then
  printf '%s\n' '--uninstall cannot be combined with --skip-deps or --deps-only' >&2
  exit 1
fi

if (( EUID == 0 )); then
  printf 'run this script as your regular user, not root\n' >&2
  exit 1
fi

backup_root="$backup_parent/$(date +%Y%m%d-%H%M%S)"
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

build_managed_targets() {
  local -n out_ref="$1"
  local item

  out_ref=()

  for item in "${config_dirs[@]}"; do
    out_ref+=( "$HOME/.config/$item" )
  done

  for item in "${config_files[@]}"; do
    out_ref+=( "$HOME/.config/$item" )
  done

  for item in "${picture_files[@]}"; do
    out_ref+=( "$HOME/Pictures/$item" )
  done
}

build_seed_targets() {
  local -n out_ref="$1"
  local item

  out_ref=()

  for item in "${state_seed_files[@]}"; do
    out_ref+=( "$HOME/.local/state/$item" )
  done

  out_ref+=(
    "$HOME/.config/caelestia/hypr-user.local.conf"
    "$HOME/.config/caelestia/hypr-execs.local.conf"
    "$HOME/.config/caelestia/user-config.fish"
    "$HOME/.local/state/caelestia/wallpaper/path.txt"
  )
}

write_install_state() {
  local item

  if (( dry_run )); then
    printf '+ write install state %q\n' "$install_state_file"
    return 0
  fi

  mkdir -p "$install_state_dir"

  {
    printf 'state_repo_root=%q\n' "$repo_root"
    printf 'state_backup_root=%q\n' "$backup_root"
    printf 'state_linked_targets=(\n'
    for item in "${linked_targets[@]}"; do
      printf '  %q\n' "$item"
    done
    printf ')\n'
    printf 'state_created_seed_paths=(\n'
    for item in "${created_seed_paths[@]}"; do
      printf '  %q\n' "$item"
    done
    printf ')\n'
  } > "$install_state_file"

  printf 'state %s\n' "$install_state_file"
}

load_install_state() {
  if [[ ! -f "$install_state_file" ]]; then
    return 1
  fi

  # shellcheck disable=SC1090
  source "$install_state_file"
}

find_latest_backup_root() {
  local latest=""

  if [[ -d "$backup_parent" ]]; then
    latest="$(find "$backup_parent" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | tail -n 1)"
  fi

  if [[ -n "$latest" ]]; then
    printf '%s/%s\n' "$backup_parent" "$latest"
  fi
}

path_is_managed_link() {
  local path="$1"
  local managed_root="$2"
  local resolved=""

  if [[ ! -L "$path" ]]; then
    return 1
  fi

  resolved="$(readlink -f "$path" || true)"
  [[ "$resolved" == "$managed_root" || "$resolved" == "$managed_root/"* ]]
}

remove_path() {
  local path="$1"

  if [[ ! -e "$path" && ! -L "$path" ]]; then
    printf 'skip  %s\n' "$path"
    return 0
  fi

  run rm -rf "$path"
  printf 'remove %s\n' "$path"
}

restore_managed_target() {
  local dst="$1"
  local managed_root="$2"
  local restore_root="$3"
  local backup_path=""

  if [[ -n "$restore_root" ]]; then
    backup_path="$restore_root/${dst#"$HOME"/}"
  fi

  if [[ -n "$backup_path" && ( -e "$backup_path" || -L "$backup_path" ) ]]; then
    if [[ -e "$dst" || -L "$dst" ]]; then
      run rm -rf "$dst"
    fi
    run mkdir -p "$(dirname "$dst")"
    run mv "$backup_path" "$dst"
    printf 'restore %s <- %s\n' "$dst" "$backup_path"
    return 0
  fi

  if path_is_managed_link "$dst" "$managed_root"; then
    remove_path "$dst"
    return 0
  fi

  if [[ ! -e "$dst" && ! -L "$dst" ]]; then
    printf 'skip  %s\n' "$dst"
    return 0
  fi

  printf 'keep  %s\n' "$dst"
}

seed_text_matches_default() {
  local path="$1"
  local expected=""
  local content=""

  case "$path" in
    "$HOME/.config/caelestia/hypr-user.local.conf")
      expected="# Machine-specific monitor overrides for this host."
      ;;
    "$HOME/.config/caelestia/hypr-execs.local.conf")
      expected="# Machine-specific startup programs for this host."
      ;;
    "$HOME/.config/caelestia/user-config.fish")
      expected="# Machine-specific shell config for this host."
      ;;
    "$HOME/.local/state/caelestia/wallpaper/path.txt")
      expected="$HOME/Pictures/${picture_files[0]}"
      ;;
    *)
      return 1
      ;;
  esac

  if [[ ! -f "$path" ]]; then
    return 1
  fi

  content="$(<"$path")"
  [[ "$content" == "$expected" ]]
}

seed_file_matches_default() {
  local path="$1"

  case "$path" in
    "$HOME/.local/state/caelestia/scheme.json")
      [[ -f "$path" ]] && cmp -s "$state_seed_root/caelestia/scheme.json" "$path"
      ;;
    *)
      seed_text_matches_default "$path"
      ;;
  esac
}

uninstall_dotfiles() {
  local managed_root="$repo_root"
  local restore_root=""
  local state_loaded=0
  local item
  local targets=()
  local seed_targets=()

  if load_install_state; then
    state_loaded=1
    managed_root="${state_repo_root:-$repo_root}"
    restore_root="${state_backup_root:-}"
    targets=( "${state_linked_targets[@]}" )
    seed_targets=( "${state_created_seed_paths[@]}" )
  else
    restore_root="$(find_latest_backup_root)"
    build_managed_targets targets
    build_seed_targets seed_targets
  fi

  if (( ${#targets[@]} == 0 )); then
    build_managed_targets targets
  fi

  for item in "${targets[@]}"; do
    restore_managed_target "$item" "$managed_root" "$restore_root"
  done

  if (( state_loaded )); then
    for item in "${seed_targets[@]}"; do
      remove_path "$item"
    done
  else
    for item in "${seed_targets[@]}"; do
      if [[ ! -e "$item" && ! -L "$item" ]]; then
        printf 'skip  %s\n' "$item"
        continue
      fi

      if seed_file_matches_default "$item"; then
        remove_path "$item"
      else
        printf 'keep  %s\n' "$item"
      fi
    done
  fi

  if (( dry_run )); then
    printf '+ rm -f %q\n' "$install_state_file"
    return 0
  fi

  rm -f "$install_state_file"
}

backup_and_link() {
  local src="$1"
  local dst="$2"
  local resolved_src resolved_dst backup_path

  linked_targets+=( "$dst" )
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
  created_seed_paths+=( "$dst" )
  printf 'seed  %s <- %s\n' "$dst" "$src"
}

seed_text_file_if_missing() {
  local dst="$1"
  local content="$2"

  if [[ -e "$dst" || -L "$dst" ]]; then
    printf 'skip  %s\n' "$dst"
    return 0
  fi

  run mkdir -p "$(dirname "$dst")"
  write_text_file "$dst" "$content"
  created_seed_paths+=( "$dst" )
  printf 'seed  %s\n' "$dst"
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
  created_seed_paths+=( "$dst" )
  printf 'seed  %s <- %s\n' "$dst" "$wallpaper_path"
}

seed_runtime_state() {
  local item

  for item in "${state_seed_files[@]}"; do
    seed_file_if_missing "$state_seed_root/$item" "$HOME/.local/state/$item"
  done

  seed_text_file_if_missing "$HOME/.config/caelestia/hypr-user.local.conf" "# Machine-specific monitor overrides for this host."
  seed_text_file_if_missing "$HOME/.config/caelestia/hypr-execs.local.conf" "# Machine-specific startup programs for this host."
  seed_text_file_if_missing "$HOME/.config/caelestia/user-config.fish" "# Machine-specific shell config for this host."
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

if (( uninstall )); then
  uninstall_dotfiles
  if (( dry_run )); then
    printf 'dry run complete\n'
  else
    printf 'uninstall complete\n'
  fi
  exit 0
fi

if (( ! skip_deps )); then
  install_dependencies
fi

if (( ! deps_only )); then
  link_dotfiles
  seed_runtime_state
  write_install_state
fi

if (( dry_run )); then
  printf 'dry run complete\n'
else
  printf 'install complete\n'
fi
