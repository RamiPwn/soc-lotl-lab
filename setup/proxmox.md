# Proxmox VE Setup

This section explains how Proxmox VE was used to host the internal components of the SOC-LOTL-Lab.

Proxmox provides the virtualization layer for:

- OPNsense;
- the Wazuh server;
- the Windows workstation.

Kali Linux was kept outside the internal infrastructure to represent an external attacker.

![Proxmox Lab](../assets/proxmox-lab.png)

---

## Virtual Machines

| Machine | Role |
|---|---|
| OPNsense | Firewall, routing and segmentation |
| Wazuh | Centralized monitoring and detection |
| Windows 11 | Monitored workstation |

Example resources:

| Machine | CPU | RAM | Disk |
|---|---:|---:|---:|
| OPNsense | 2 cores | 2–4 GB | 20 GB |
| Wazuh | 4 cores | 8 GB | 80 GB |
| Windows 11 | 2–4 cores | 4–8 GB | 64 GB |

These values can be adapted to the available hardware.

---

## Network Bridges

Proxmox bridges connect the virtual machines to the different network zones.

| Bridge | Purpose |
|---|---|
| `vmbr0` | Proxmox management |
| `vmbr1` | OPNsense WAN |
| `vmbr2` | Internal lab networks |

The internal bridge must be VLAN-aware so that OPNsense can manage the SOC, Users and DMZ networks.

A reusable example is available here:

[`configs/proxmox/interfaces.example`](../configs/proxmox/interfaces.example)

---

## OPNsense VM

The OPNsense VM uses two network interfaces:

| Interface | Bridge | Purpose |
|---|---|---|
| WAN | `vmbr1` | External network |
| LAN | `vmbr2` | Internal VLAN trunk |

Do not configure a VLAN tag on the OPNsense LAN adapter in Proxmox. VLANs are created directly inside OPNsense.

---

## Wazuh VM

The Wazuh server is connected to the SOC network.

```text
Bridge: vmbr2
VLAN tag: SOC VLAN ID
```

---

## Windows VM

The Windows workstation is connected to the Users network.

```text
Bridge: vmbr2
VLAN tag: Users VLAN ID
```

---

## Validation

Before continuing, verify that:

- OPNsense has one WAN interface and one internal interface;
- `vmbr2` is VLAN-aware;
- Wazuh is connected to the SOC VLAN;
- Windows is connected to the Users VLAN.

Useful command:

```bash
cat /etc/network/interfaces
```

---

## Next Step

Continue with the firewall and VLAN configuration:

[OPNsense Setup](opnsense.md)
