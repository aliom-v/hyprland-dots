#!/usr/bin/env bash

set -euo pipefail

action="${1:-}"
direction="${2:-}"

if [[ ! "$action" =~ ^(focus|swapcol)$ ]]; then
    exit 1
fi

if [[ ! "$direction" =~ ^(l|r)$ ]]; then
    exit 1
fi

active_json="$(hyprctl -j activewindow 2>/dev/null || true)"
clients_json="$(hyprctl -j clients 2>/dev/null || true)"

if [[ -z "$active_json" || -z "$clients_json" ]]; then
    exit 0
fi

is_mapped="$(jq -r '.mapped // false' <<<"$active_json")"
is_floating="$(jq -r '.floating // false' <<<"$active_json")"
workspace_id="$(jq -r '.workspace.id // empty' <<<"$active_json")"
monitor_id="$(jq -r '.monitor // empty' <<<"$active_json")"
active_x="$(jq -r '.at[0] // empty' <<<"$active_json")"

if [[ "$is_mapped" != "true" || "$is_floating" != "false" ]]; then
    exit 0
fi

if [[ -z "$workspace_id" || -z "$monitor_id" || -z "$active_x" ]]; then
    exit 0
fi

# Scrolling columns share the same x origin. Only dispatch when a neighbor
# column exists in the requested direction so focus/swap does not wrap around.
if [[ "$direction" == "l" ]]; then
    has_neighbor="$(jq --argjson workspace_id "$workspace_id" --argjson monitor_id "$monitor_id" --argjson active_x "$active_x" '
        [ .[]
          | select(.workspace.id == $workspace_id)
          | select(.monitor == $monitor_id)
          | select((.floating // false) | not)
          | select((.pinned // false) | not)
          | select((.fullscreen // 0) == 0)
          | .at[0]
        ]
        | unique
        | any(. < ($active_x - 1))
    ' <<<"$clients_json")"
else
    has_neighbor="$(jq --argjson workspace_id "$workspace_id" --argjson monitor_id "$monitor_id" --argjson active_x "$active_x" '
        [ .[]
          | select(.workspace.id == $workspace_id)
          | select(.monitor == $monitor_id)
          | select((.floating // false) | not)
          | select((.pinned // false) | not)
          | select((.fullscreen // 0) == 0)
          | .at[0]
        ]
        | unique
        | any(. > ($active_x + 1))
    ' <<<"$clients_json")"
fi

if [[ "$has_neighbor" != "true" ]]; then
    exit 0
fi

hyprctl dispatch layoutmsg "$action $direction" >/dev/null 2>&1
