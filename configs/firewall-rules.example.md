# OPNsense Firewall Rules Template

This file summarizes the firewall rules used by the lab.

Replace all placeholder addresses with the values used in your environment.

---

## Network Objects

```text
MANAGEMENT_NET = <MANAGEMENT_NETWORK>
SOC_NET        = <SOC_NETWORK>
USERS_NET      = <USERS_NETWORK>
DMZ_NET        = <DMZ_NETWORK>
WAZUH_SERVER   = <WAZUH_IP>
```
## WAN Information

```text
ISP_ROUTER      = 192.168.1.1
OPNSENSE_WAN    = 192.168.1.50
WAN_NETWORK     = 192.168.1.0/24
```

## Management Rules

| Action | Source | Destination | Port | Description |
|---|---|---|---|---|
| Allow | `MANAGEMENT_NET` | OPNsense | 443 | Firewall administration |
| Allow | `MANAGEMENT_NET` | Proxmox | 8006 | Proxmox administration |
| Block | Any other network | `MANAGEMENT_NET` | Any | Protect management services |

---

## Users Rules

| Action | Source | Destination | Port | Description |
|---|---|---|---|---|
| Allow | `USERS_NET` | `WAZUH_SERVER` | 1514/TCP | Wazuh event forwarding |
| Allow | `USERS_NET` | `WAZUH_SERVER` | 1515/TCP | Wazuh agent enrollment |
| Allow | `USERS_NET` | Any | 80/TCP | HTTP access |
| Allow | `USERS_NET` | Any | 443/TCP | HTTPS access |
| Block | `USERS_NET` | `MANAGEMENT_NET` | Any | Protect management network |
| Block | `USERS_NET` | `SOC_NET` | Any | Block other SOC services |

Place the specific Wazuh allow rules above the general SOC block rule.

---

## SOC Rules

| Action | Source | Destination | Port | Description |
|---|---|---|---|---|
| Allow | `SOC_NET` | Any | 80/TCP | Updates |
| Allow | `SOC_NET` | Any | 443/TCP | Updates |
| Block | `SOC_NET` | `MANAGEMENT_NET` | Any | Protect management network |

---

## DMZ Rules

| Action | Source | Destination | Port | Description |
|---|---|---|---|---|
| Block | `DMZ_NET` | `MANAGEMENT_NET` | Any | Protect management network |
| Block | `DMZ_NET` | `SOC_NET` | Any | Protect SOC network |
| Block | `DMZ_NET` | `USERS_NET` | Any | Protect user systems |

---

## WAN Rules

No inbound WAN rule should expose the internal SOC, Users or Management networks.

```text
WAN → Internal networks: Block
```

Only add an inbound rule when a specific lab test requires it.
