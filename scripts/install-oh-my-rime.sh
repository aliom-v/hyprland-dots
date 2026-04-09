#!/usr/bin/env bash
set -euo pipefail

repo_url="${OH_MY_RIME_REPO:-https://github.com/Mintimate/oh-my-rime.git}"
branch="${OH_MY_RIME_BRANCH:-main}"
target_dir="${XDG_CONFIG_HOME:-$HOME/.config}/ibus/rime"
tmp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

if ! command -v git >/dev/null 2>&1; then
  printf 'git is required to install oh-my-rime\n' >&2
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  printf 'rsync is required to install oh-my-rime\n' >&2
  exit 1
fi

printf 'clone %s\n' "$repo_url"
git clone --depth=1 --branch "$branch" "$repo_url" "$tmp_dir/repo"

mkdir -p "$target_dir"

# Sync the distributable Rime files while preserving local build artifacts and user data.
rsync -a --delete \
  --exclude '.git' \
  --exclude '.github' \
  --exclude '.ide' \
  --exclude 'build' \
  --exclude 'installation.yaml' \
  --exclude 'user.yaml' \
  --exclude '*.userdb' \
  --exclude 'sync' \
  "$tmp_dir/repo/" "$target_dir/"

cat > "$target_dir/default.custom.yaml" <<'EOF'
patch:
  schema_list:
    - schema: double_pinyin_flypy
EOF

printf 'write %s\n' "$target_dir/default.custom.yaml"
printf 'done  oh-my-rime -> %s\n' "$target_dir"
