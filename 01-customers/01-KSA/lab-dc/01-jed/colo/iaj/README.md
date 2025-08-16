# README – Colo / Customer Provisioning in DC

This document describes how to provision a colo or customer in our DC fabric.
We use **FRR + Containerlab** with a combination of VRFs and NAT rules to provide a customer with a **dedicated handoff** and **public IP mapping**.

---

## 🏗️ Steps Taken for Customer IAJ (Single Host Example)

### 1. Create a VRF on leaf

* On the DC leaf (`l3`) we create a VRF named **iaj**.
* The VRF isolates the customer traffic from the default routing table.
* Customer handoff is attached to this VRF.

```bash
ip link add iaj type vrf table 1001
ip link set iaj up
ip link set dev eth3 master iaj
ip link set eth3 up
```

👉 This is automated in `iaj.clab.yml` under the `exec` block for `l3`.

---

### 2. Customer handoff via bridge

* A **Containerlab bridge** (`lab-dc`) represents the customer handoff port.
* `l3:eth3` is connected to this bridge.
* The customer VM/container (IAJ Proxmox node) connects to this same bridge and receives a **private handoff IP** (e.g., `10.111.113.2/30`).

---

### 3. Assign public IP with 1:1 NAT (on leaf)

* The customer expects a **public IP** (e.g., `203.0.113.9/32`).
* Instead of configuring it on the VM, we provide it via **1:1 NAT** on the leaf router (`l3`).

```bash
iptables -t nat -A PREROUTING -d 203.0.113.9/32 -j DNAT --to-destination 10.111.113.2
iptables -t nat -A POSTROUTING -s 10.111.113.2/32 -j SNAT --to-source 203.0.113.9
```

This way:

* From outside → traffic to `203.0.113.9` is redirected to `10.111.113.2`.
* From inside → traffic from `10.111.113.2` is translated to `203.0.113.9`.

---

### 4. Handle default SNAT on CE

* The CE router (`ce-01`) has a **default SNAT rule** (all traffic out → `203.0.113.1`).
* Without adjustment, customer traffic would be rewritten incorrectly.
* We **insert a bypass rule** to exempt the customer public IP:

```bash
iptables -t nat -I POSTROUTING 1 -s 203.0.113.9/32 -j ACCEPT
```

This ensures customer traffic goes out with its assigned public IP, not with CE’s global SNAT.

---

### 5. Test connectivity

* From inside the DC, ping `one.one.one.one` (Cloudflare DNS) using the customer VM:

```bash
ping 1.1.1.1
```

* Capture at CE to confirm traffic keeps its public source:

```bash
tcpdump -i eth1 icmp
```

* From outside the ISP network, connect to customer’s public IP:

```bash
ssh srvadmin@203.0.113.9
```

This should land directly on the customer VM (`10.111.113.2`).

---

## ✅ Summary of Roles

* **Leaf (l3)**

  * Provides VRF isolation per customer.
  * Performs **1:1 NAT** between customer private handoff IP and assigned public IP.

* **CE (ce-01)**

  * Does global SNAT for DC traffic.
  * Has **bypass rules** so customer-assigned public IPs are not re-NATed.

* **Customer VM (IAJ)**

  * Sees only its private IP (10.111.113.2).
  * Still accessible via the mapped public IP (203.0.113.9).

---

## 🔄 Lifecycle

1. Add a new block in `iaj.clab.yml` for customer’s NAT mapping.
2. Allocate a VRF + bridge for isolation.
3. Configure NAT rules on **l3** for public ↔ private.
4. Add SNAT bypass rules on **ce-01**.
5. Test from both inside and outside.

---
