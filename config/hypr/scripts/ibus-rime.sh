#!/usr/bin/env bash
set -euo pipefail

if ! command -v ibus-daemon >/dev/null 2>&1; then
  exit 0
fi

ibus-daemon -drxR

if ! command -v gsettings >/dev/null 2>&1; then
  exit 0
fi

# Keep the session on Rime only. English input uses Rime's Latin mode.
gsettings set org.freedesktop.ibus.general preload-engines "['rime']"
gsettings set org.freedesktop.ibus.general engines-order "['rime']"
gsettings set org.freedesktop.ibus.general use-system-keyboard-layout true

for _ in $(seq 1 20); do
  if ibus list-engine >/dev/null 2>&1; then
    break
  fi
  sleep 0.2
done

ibus engine rime >/dev/null 2>&1 || true
