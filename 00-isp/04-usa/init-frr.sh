#!/usr/bin/env bash
set -euo pipefail

OVERWRITE=false
if [[ "${1:-}" == "-f" ]]; then
  OVERWRITE=true
  shift || true
fi

CONFIG_DIR="config"

ROUTERS=(
  ix-01 ix-02
  core-01 core-02
  metro-01 metro-02
  ny-01 dc-01 ca-01
)

if [[ "$#" -gt 0 ]]; then
  ROUTERS=("$@")
fi

mkdir -p "$CONFIG_DIR"

for R in "${ROUTERS[@]}"; do
  DIR="$CONFIG_DIR/$R"
  mkdir -p "$DIR"

  # Empty frr.conf
  if [[ ! -f "$DIR/frr.conf" || "$OVERWRITE" == "true" ]]; then
    : > "$DIR/frr.conf"
  fi

  # Empty vtysh.conf
  if [[ ! -f "$DIR/vtysh.conf" || "$OVERWRITE" == "true" ]]; then
    : > "$DIR/vtysh.conf"
  fi

  # Daemons file
  if [[ ! -f "$DIR/daemons" || "$OVERWRITE" == "true" ]]; then
    cat <<'EOF' > "$DIR/daemons"
# This file tells the frr package which daemons to start.
# ...
bgpd=yes
ospfd=yes
ospf6d=no
ripd=no
ripngd=no
isisd=no
pimd=no
pim6d=no
ldpd=no
nhrpd=no
eigrpd=no
babeld=no
sharpd=no
pbrd=no
bfdd=yes
fabricd=no
vrrpd=no
pathd=no

vtysh_enable=yes
zebra_options="  -A 127.0.0.1 -s 90000000"
bgpd_options="   -A 127.0.0.1"
ospfd_options="  -A 127.0.0.1"
ospf6d_options=" -A ::1"
ripd_options="   -A 127.0.0.1"
ripngd_options=" -A ::1"
isisd_options="  -A 127.0.0.1"
pimd_options="   -A 127.0.0.1"
pim6d_options="  -A ::1"
ldpd_options="   -A 127.0.0.1"
nhrpd_options="  -A 127.0.0.1"
eigrpd_options=" -A 127.0.0.1"
babeld_options=" -A 127.0.0.1"
sharpd_options=" -A 127.0.0.1"
pbrd_options="   -A 127.0.0.1"
staticd_options="-A 127.0.0.1"
bfdd_options="   -A 127.0.0.1"
fabricd_options="-A 127.0.0.1"
vrrpd_options="  -A 127.0.0.1"
pathd_options="  -A 127.0.0.1"
EOF
  fi
done

echo "✅ Created config folders for ${#ROUTERS[@]} routers in '$CONFIG_DIR'."
