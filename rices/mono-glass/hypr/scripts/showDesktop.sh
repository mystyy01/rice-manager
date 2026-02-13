#!/usr/bin/env bash
set -euo pipefail

# Robust "Show Desktop" for Hyprland:
# - First press: switches every monitor to an (ideally empty) workspace.
# - Second press: restores each monitor back to its previous workspace.
#
# State lives in /tmp, so it resets on reboot.

STATE_FILE="/tmp/hypr-showdesktop.json"
EMPTY_WS="99"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing dependency: $1" >&2
    exit 1
  }
}

need hyprctl
need jq

restore() {
  local count focused_monitor
  count="$(jq 'if type=="object" then (.monitors|length) else 0 end' "$STATE_FILE" 2>/dev/null || echo 0)"
  focused_monitor="$(jq -r '.focused_monitor // empty' "$STATE_FILE" 2>/dev/null || true)"

  if [[ "${count:-0}" == "0" ]]; then
    rm -f "$STATE_FILE"
    exit 0
  fi

  jq -r '.monitors[] | [.name, .workspace] | @tsv' "$STATE_FILE" |
    while IFS=$'\t' read -r mon ws; do
      [[ -n "$mon" && -n "$ws" ]] || continue
      hyprctl dispatch focusmonitor "$mon" >/dev/null 2>&1 || true
      hyprctl dispatch workspace "$ws" >/dev/null 2>&1 || true
    done

  rm -f "$STATE_FILE"

  [[ -n "${focused_monitor:-}" ]] && hyprctl dispatch focusmonitor "$focused_monitor" >/dev/null 2>&1 || true
}

stash() {
  # Record current workspace for each monitor, then switch all monitors
  # to a single workspace (ideally empty).
  local focused_monitor
  focused_monitor="$(hyprctl -j activeworkspace | jq -r '.monitor')"

  hyprctl -j monitors |
    jq --arg fm "$focused_monitor" '
      {
        focused_monitor: $fm,
        monitors: [
          .[]
          | {name: .name, workspace: (.activeWorkspace.name // (.activeWorkspace.id|tostring))}
        ]
      }' >"$STATE_FILE"

  jq -r '.monitors[].name' "$STATE_FILE" | while read -r mon; do
    [[ -n "$mon" ]] || continue
    hyprctl dispatch focusmonitor "$mon" >/dev/null 2>&1 || true
    hyprctl dispatch workspace "$EMPTY_WS" >/dev/null 2>&1 || true
  done

  [[ -n "${focused_monitor:-}" ]] && hyprctl dispatch focusmonitor "$focused_monitor" >/dev/null 2>&1 || true
}

if [[ -f "$STATE_FILE" ]]; then
  restore
else
  stash
fi
