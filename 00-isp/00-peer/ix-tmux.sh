#!/usr/bin/env bash
set -euo pipefail

SESSION="IXs"

# Define all IX routers in order
ORDER=(
  sa-ix-01
  sa-ix-02
  ae-ix-01
  ae-ix-02
  pk-ix-01
  pk-ix-02
  us-ix-01
  us-ix-02
)

FRESH=false
ARGS=()
for a in "$@"; do
  if [[ "$a" == "--fresh" ]]; then FRESH=true; else ARGS+=("$a"); fi
done
if ((${#ARGS[@]} > 0)); then ORDER=("${ARGS[@]}"); fi

cmd_for() {
  local n="$1"
  echo "docker exec -it ${n} vtysh || docker exec -it ${n} bash -l || docker exec -it ${n} sh -l"
}

if $FRESH && tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux kill-session -t "$SESSION"
fi

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  first="${ORDER[0]}"
  tmux new-session -d -s "$SESSION" -n "$first" "$(cmd_for "$first")"
fi

for name in "${ORDER[@]}"; do
  if ! tmux list-windows -t "$SESSION" -F '#W' | grep -qx "$name"; then
    tmux new-window -t "$SESSION" -n "$name" "$(cmd_for "$name")"
  fi
done

tmux set-option -t "$SESSION" remain-on-exit on
tmux select-window -t "$SESSION:${ORDER[0]}"
exec tmux attach -t "$SESSION"
