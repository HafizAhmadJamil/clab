#!/usr/bin/env bash
set -euo pipefail

SESSION="LAB-DC"

# Mapping of window names to container names
declare -A DEVICES=(
    ["ce-01"]="ce-01"
    ["spine-01"]="sp1"
    ["spine-02"]="sp2"
    ["leaf-01"]="l1"
    ["leaf-02"]="l2"
    ["leaf-03"]="l3"
)

# Order of windows to create
ORDER=(
    ce-01
    spine-01
    spine-02
    leaf-01
    leaf-02
    leaf-03
)

FRESH=false
ARGS=()
for a in "$@"; do
    if [[ "$a" == "--fresh" ]]; then FRESH=true; else ARGS+=("$a"); fi
done
if ((${#ARGS[@]} > 0)); then ORDER=("${ARGS[@]}"); fi

cmd_for() {
    local container="$1"
    echo "docker exec -it ${container} vtysh || docker exec -it ${container} bash -l || docker exec -it ${container} sh -l"
}

if $FRESH && tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux kill-session -t "$SESSION"
fi

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    first_window="${ORDER[0]}"
    first_container="${DEVICES[$first_window]}"
    tmux new-session -d -s "$SESSION" -n "$first_window" "$(cmd_for "$first_container")"
fi

for window_name in "${ORDER[@]}"; do
    container_name="${DEVICES[$window_name]}"
    if ! tmux list-windows -t "$SESSION" -F '#W' | grep -qx "$window_name"; then
        tmux new-window -t "$SESSION" -n "$window_name" "$(cmd_for "$container_name")"
    fi
done

tmux set-option -t "$SESSION" remain-on-exit on
tmux select-window -t "$SESSION:${ORDER[0]}"
exec tmux attach -t "$SESSION"
