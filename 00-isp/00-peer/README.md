# Interconnect Peering Plan

This document describes the interconnect (peer) topology between regional Internet Exchange (IX) nodes across KSA, UAE, PAK, and USA.
All links are built as **dedicated point-to-point /30 subnets**, carried on `eth11–eth16` of each IX container.

## ASNs per Region

* **KSA** → ASN **65101**
* **UAE** → ASN **65102**
* **PAK** → ASN **65103**
* **USA** → ASN **65104**

Each IX router establishes **eBGP sessions** with its peer(s) across these links, exchanging loopbacks and customer/metro prefixes.
This ensures clean separation: all inter-region connectivity is **eBGP**, while intra-region (core ↔ metro ↔ IX) remains under **iBGP or IGP**.

---

## Peering Topology

| Region Pair | Local IX        | Remote IX       | Local Intf/IP | Remote Intf/IP | Prefix (/30)   |
| ----------- | --------------- | --------------- | ------------- | -------------- | -------------- |
| KSA–UAE     | sa-ix-01\:eth11 | ae-ix-01\:eth11 | 172.16.0.1    | 172.16.0.2     | 172.16.0.0/30  |
| KSA–UAE     | sa-ix-01\:eth12 | ae-ix-02\:eth11 | 172.16.0.5    | 172.16.0.6     | 172.16.0.4/30  |
| KSA–UAE     | sa-ix-02\:eth11 | ae-ix-01\:eth12 | 172.16.0.9    | 172.16.0.10    | 172.16.0.8/30  |
| KSA–UAE     | sa-ix-02\:eth12 | ae-ix-02\:eth12 | 172.16.0.13   | 172.16.0.14    | 172.16.0.12/30 |
| KSA–PAK     | sa-ix-01\:eth13 | pk-ix-01\:eth11 | 172.16.0.17   | 172.16.0.18    | 172.16.0.16/30 |
| KSA–PAK     | sa-ix-01\:eth14 | pk-ix-02\:eth11 | 172.16.0.21   | 172.16.0.22    | 172.16.0.20/30 |
| KSA–PAK     | sa-ix-02\:eth13 | pk-ix-01\:eth12 | 172.16.0.25   | 172.16.0.26    | 172.16.0.24/30 |
| KSA–PAK     | sa-ix-02\:eth14 | pk-ix-02\:eth12 | 172.16.0.29   | 172.16.0.30    | 172.16.0.28/30 |
| KSA–USA     | sa-ix-01\:eth15 | us-ix-01\:eth11 | 172.16.0.33   | 172.16.0.34    | 172.16.0.32/30 |
| KSA–USA     | sa-ix-01\:eth16 | us-ix-02\:eth11 | 172.16.0.37   | 172.16.0.38    | 172.16.0.36/30 |
| KSA–USA     | sa-ix-02\:eth15 | us-ix-01\:eth12 | 172.16.0.41   | 172.16.0.42    | 172.16.0.40/30 |
| KSA–USA     | sa-ix-02\:eth16 | us-ix-02\:eth12 | 172.16.0.45   | 172.16.0.46    | 172.16.0.44/30 |
| UAE–PAK     | ae-ix-01\:eth13 | pk-ix-01\:eth13 | 172.16.0.49   | 172.16.0.50    | 172.16.0.48/30 |
| UAE–PAK     | ae-ix-01\:eth14 | pk-ix-02\:eth13 | 172.16.0.53   | 172.16.0.54    | 172.16.0.52/30 |
| UAE–PAK     | ae-ix-02\:eth13 | pk-ix-01\:eth14 | 172.16.0.57   | 172.16.0.58    | 172.16.0.56/30 |
| UAE–PAK     | ae-ix-02\:eth14 | pk-ix-02\:eth14 | 172.16.0.61   | 172.16.0.62    | 172.16.0.60/30 |
| UAE–USA     | ae-ix-01\:eth15 | us-ix-01\:eth13 | 172.16.0.65   | 172.16.0.66    | 172.16.0.64/30 |
| UAE–USA     | ae-ix-01\:eth16 | us-ix-02\:eth13 | 172.16.0.69   | 172.16.0.70    | 172.16.0.68/30 |
| UAE–USA     | ae-ix-02\:eth15 | us-ix-01\:eth14 | 172.16.0.73   | 172.16.0.74    | 172.16.0.72/30 |
| UAE–USA     | ae-ix-02\:eth16 | us-ix-02\:eth14 | 172.16.0.77   | 172.16.0.78    | 172.16.0.76/30 |
| PAK–USA     | pk-ix-01\:eth15 | us-ix-01\:eth15 | 172.16.0.81   | 172.16.0.82    | 172.16.0.80/30 |
| PAK–USA     | pk-ix-01\:eth16 | us-ix-02\:eth15 | 172.16.0.85   | 172.16.0.86    | 172.16.0.84/30 |
| PAK–USA     | pk-ix-02\:eth15 | us-ix-01\:eth16 | 172.16.0.89   | 172.16.0.90    | 172.16.0.88/30 |
| PAK–USA     | pk-ix-02\:eth16 | us-ix-02\:eth16 | 172.16.0.93   | 172.16.0.94    | 172.16.0.92/30 |

---

## eBGP Plan

* Each IX router will run **BGP with its regional ASN**:

  * `sa-ix-*` → ASN 65101
  * `ae-ix-*` → ASN 65102
  * `pk-ix-*` → ASN 65103
  * `us-ix-*` → ASN 65104

* On each /30 interconnect, configure an **eBGP neighbor** with:

  * Remote ASN = the ASN of the peer region
  * Update-source = directly the physical interface (`eth11–eth16`)
  * No route-reflector setup (this is true eBGP)
  * Each IX advertises its loopback /32 and any customer or metro aggregates

### Example (on `sa-ix-01` → peer `ae-ix-01`):

```frr
router bgp 65101
 neighbor 172.16.0.2 remote-as 65102
 neighbor 172.16.0.2 description ae-ix-01
 !
 address-family ipv4 unicast
  neighbor 172.16.0.2 activate
  neighbor 172.16.0.2 next-hop-self
 exit-address-family
!
```

---

✅ With this design:

* **Intra-region traffic**: stays inside KSA/UAE/PAK/US using IGP/iBGP.
* **Inter-region traffic**: always crosses an eBGP edge, clean ASN boundaries.
* **Scalability**: Adding new IX or region only requires assigning new ASN + /30s.

