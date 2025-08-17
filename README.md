```bash
# List all running containers based on the FRR image and show their running configuration,
# extracting interface, description, and IP address details.
docker ps --filter "ancestor=ghcr.io/miajdev/frr" --format '{{.Names}}' \
| while read -r c; do
    echo "=== $c ==="
    docker exec "$c" vtysh -c "show running-config" \
    | awk '
        /^interface/ {
            iface=$2
            desc=""
        }
        /^ description/ {
            desc=$0
        }
        /^ ip address/ {
            if (desc == "") {
                print iface, ":", "no description", ":", $3
            } else {
                print iface, ":", desc, ":", $3
            }
        }'
done


# Define a list of loopback IP addresses to test connectivity.
LOOPS="10.255.11.1 10.255.11.2 10.255.11.3 10.255.11.4 10.255.11.5 10.255.11.6 10.255.11.7 10.255.11.8 10.255.11.9"

# For each specified container, ping each loopback IP and report if reachable.
for c in sa-ix-01 sa-ix-02 sa-core-01 sa-core-02 sa-metro-01 sa-metro-02 sa-jed-01 sa-dmm-01 sa-ruh-01; do
    echo "=== $c ==="
    for ip in $LOOPS; do
        docker exec "$c" ping -c1 -w1 "$ip" >/dev/null && echo "OK  $ip" || echo "FAIL $ip"
    done
done

# For each FRR container, display a brief summary of BFD peers.
docker ps --filter "ancestor=ghcr.io/miajdev/frr" --format '{{.Names}}' \
| while read -r c; do
    echo "=== $c ==="
    docker exec "$c" vtysh -c "show bfd peers brief"
done

# For each FRR container, show OSPF neighbor information.
docker ps --filter "ancestor=ghcr.io/miajdev/frr" --format '{{.Names}}' \
| while read -r c; do
    printf "=== %s ===\n" "$c"
    docker exec "$c" vtysh -c "show ip ospf neighbor"
done
```
