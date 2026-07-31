# OPNsense Setup

OPNsense provides routing, VLAN segmentation and firewalling for the SOC-LOTL-Lab.

It acts as the central gateway between the Internet connection provided by the ISP router and the internal company-style networks.

![OPNsense VLANs](../assets/opnsense-vlans.png)

---

## Network Design

The lab uses one external WAN network and several internal segmented networks.

| Interface | Purpose | Example network |
|---|---|---|
| WAN | Connection to the ISP router | `192.168.1.0/24` |
| LAN / Management | Infrastructure administration | `10.0.0.0/24` |
| VLAN 10 | SOC network | `10.10.10.0/24` |
| VLAN 20 | Users network | `10.10.20.0/24` |
| VLAN 30 | DMZ network | `10.10.30.0/24` |

OPNsense is the default gateway for all internal networks.

---

## WAN Configuration

The WAN interface connects OPNsense to the ISP router.

In this lab, the ISP router uses:

```text
Network: 192.168.1.0/24
Gateway: 192.168.1.1
OPNsense WAN address: 192.168.1.50
```

The WAN address can be assigned by DHCP.

Example:

```text
Interfaces
└── WAN
    └── IPv4 Configuration Type: DHCP
```

A DHCP reservation can be created on the ISP router so that OPNsense always receives:

```text
192.168.1.50
```

OPNsense then uses the ISP router as its upstream gateway to provide Internet access to all internal VLANs.

---

## Why the WAN Interface Matters

The WAN interface is the only part of the lab that depends directly on the ISP router.

All internal systems use private networks managed by OPNsense:

```text
10.0.0.0/24
10.10.10.0/24
10.10.20.0/24
10.10.30.0/24
```

If the ISP router or Internet provider changes, the internal architecture does not need to be rebuilt.

Only the WAN configuration may need to be updated.

For example, if the new ISP router uses:

```text
192.168.0.0/24
```

instead of:

```text
192.168.1.0/24
```

the OPNsense WAN interface can simply obtain a new DHCP address from the new router.

The VLANs, firewall rules, Wazuh server and Windows endpoint can continue using the same internal addressing plan.

This makes the lab easier to move, reuse and restore after a change of router or ISP.

---

## Proxmox Interfaces

The OPNsense virtual machine uses two network adapters:

| OPNsense interface | Proxmox bridge | Role |
|---|---|---|
| WAN | `vmbr1` | Connection to the ISP router |
| LAN | `vmbr2` | Internal VLAN trunk |

The WAN bridge must be connected to the physical interface that reaches the ISP router.

The LAN adapter must not have a VLAN tag configured in Proxmox because OPNsense manages the VLANs directly.

---

## Initial Interface Assignment

After installing OPNsense, assign:

```text
WAN: Interface connected to vmbr1
LAN: Interface connected to vmbr2
```

Example:

```text
WAN: DHCP
LAN: 10.0.0.1/24
```

The OPNsense web interface can then be accessed from the management network:

```text
https://10.0.0.1
```

---

## VLAN Creation

In the OPNsense web interface:

```text
Interfaces
└── Devices
    └── VLAN
```

Create the VLANs on the internal LAN parent interface.

| VLAN | Name | Gateway |
|---:|---|---|
| 10 | SOC | `10.10.10.1/24` |
| 20 | Users | `10.10.20.1/24` |
| 30 | DMZ | `10.10.30.1/24` |

Then assign them under:

```text
Interfaces
└── Assignments
```

Enable each interface and configure its static IPv4 address.

---

## DHCP

DHCP can be enabled for the networks that require automatic addressing.

Example:

| Network | DHCP configuration |
|---|---|
| Management | Static or DHCP |
| SOC | Static addressing recommended |
| Users | `10.10.20.100` to `10.10.20.200` |
| DMZ | Static addressing recommended |

The Wazuh server should use a fixed IP address.

---

## Routing and Internet Access

The traffic path is:

```text
Internal VM
    ↓
OPNsense VLAN gateway
    ↓
OPNsense WAN: 192.168.1.50
    ↓
ISP router: 192.168.1.1
    ↓
Internet
```

OPNsense performs routing and NAT between the internal networks and the WAN interface.

The internal virtual machines do not communicate directly with the ISP router.

This keeps the internal addressing independent from the ISP network.

---

## Firewall Policy

![OPNsense Firewall Rules](../assets/opnsense-firewall-rules.png)

The firewall follows a default-deny approach.

Traffic is blocked unless a rule explicitly authorizes it.

Main rules:

| Source | Destination | Action | Purpose |
|---|---|---|---|
| Management | OPNsense | Allow | Firewall administration |
| Management | Proxmox | Allow | Hypervisor administration |
| Users | Wazuh | Allow | Wazuh agent communication |
| Users | Internet | Allow | Web and update access |
| Users | Management | Block | Protect administration |
| WAN | Internal networks | Block | Prevent inbound access |
| DMZ | Management | Block | Protect management services |

Reusable rule summary:

[Firewall rules template](../configs/opnsense/firewall-rules.example.md)

---

## Wazuh Communications

The Windows workstation must be able to reach the Wazuh server.

| Port | Protocol | Purpose |
|---:|---|---|
| 1514 | TCP | Event forwarding |
| 1515 | TCP | Agent enrollment |

Example rule:

```text
Source: Users network
Destination: Wazuh server
Ports: 1514, 1515
Action: Allow
```

---

## Internet Access Rule

The internal networks use OPNsense WAN for Internet access.

Example rule:

```text
Source: Users network
Destination: Any
Ports: 80, 443
Action: Allow
```

For the LOTL simulation, the required Kali payload port must also be allowed when needed.

---

## Validation

Verify that:

- OPNsense WAN receives `192.168.1.50`;
- OPNsense can ping `192.168.1.1`;
- OPNsense can reach the Internet;
- the internal VLAN gateways are reachable;
- Windows can reach the Wazuh server;
- Windows can access the Internet through OPNsense;
- the Users network cannot access the Management network.

Useful tests:

```text
Interfaces
└── Diagnostics
    └── Ping
```

From Windows:

```powershell
Test-NetConnection <WAZUH_IP> -Port 1514
```

```powershell
Test-NetConnection 1.1.1.1 -Port 443
```

---

## Next Step

Continue with the SOC deployment:

[Wazuh Setup](wazuh.md)
