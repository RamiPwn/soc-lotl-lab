# Company-Style SOC Homelab — Detecting Living Off the Land Attacks

> A reusable Blue Team homelab designed to approximate the segmented infrastructure and security monitoring capabilities found in a small company.

![Lab Architecture](assets/architecture.png)

---

## Project Purpose

Living Off the Land attacks abuse legitimate tools already available on a compromised operating system.

Instead of introducing an obvious malicious executable, an attacker can use trusted Windows binaries to:

- download files;
- execute commands;
- establish persistence;
- bypass basic security controls.

Because these binaries are also used for legitimate administration, detecting malicious usage requires more context than simply identifying the executable name.

This project was created to study that problem from a Blue Team perspective.

The objective was to build a homelab approaching what a small company security environment could look like, including:

- virtualized infrastructure;
- separated network zones;
- centralized security monitoring;
- Windows endpoint telemetry;
- firewall logging;
- custom behavioural detection rules;
- incident investigation;
- containment and endpoint hardening.

The Windows binaries used in the attack scenario were selected through the [LOLBAS project](https://lolbas-project.github.io/), which documents legitimate Microsoft-signed binaries and scripts that can be abused during offensive operations.

The implemented scenario demonstrates how legitimate Windows components can be combined into a simple attack chain and how a SOC can detect the resulting behaviour.

This project does not reproduce a complete production SOC. It provides a compact and reusable environment for learning, testing detection rules and experimenting with defensive controls.

---

## Repository Design

The complete project workflow is documented in this README.

Configuration files and scripts are stored separately so they can be copied, adapted and reused.

```text
SOC-LOTL-Lab/
│
├── README.md
├── assets/
├── configs/
├── docs/
├── scripts/
└── setup/
```

| Directory | Content |
|---|---|
| `assets/` | Architecture diagrams and project screenshots |
| `configs/` | Reusable Proxmox, OPNsense and Wazuh configurations |
| `docs/` | Troubleshooting, lessons learned, roadmap and references |
| `scripts/` | Payload, containment and hardening scripts |
| `setup/` | Detailed setup notes for the main components |

The project can be reproduced as documented or used as a foundation for another environment.

Network ranges, firewall rules, detection logic and defensive controls can be adapted without rebuilding the complete architecture.

---

## What This Lab Demonstrates

1. Build a company-style virtual infrastructure.
2. Separate systems into different security zones.
3. Control communications through a firewall.
4. Centralize endpoint and firewall telemetry.
5. Simulate a Living Off the Land attack.
6. Detect each stage with custom Wazuh rules.
7. Correlate the events into an attack chain.
8. Map the activity to MITRE ATT&CK.
9. Investigate and contain the source.
10. Apply endpoint hardening.
11. Repeat the attack to validate the remediation.

---

## Technologies

| Technology | Role |
|---|---|
| Proxmox VE | Virtualization platform |
| OPNsense | Routing, VLAN segmentation and firewalling |
| Wazuh | SIEM, log collection and detection |
| Sysmon | Detailed Windows endpoint telemetry |
| Windows 11 | Monitored workstation |
| Kali Linux | External attack simulation |
| CrowdSec | Source-IP containment demonstration |
| MITRE ATT&CK | Classification of detected techniques |

---

# Lab Architecture

The environment is hosted on Proxmox VE and divided into separate network zones.

| Zone | Purpose |
|---|---|
| Management | Infrastructure administration |
| SOC | Security monitoring and log analysis |
| Users | Windows endpoint environment |
| WAN | External network and attacker simulation |
| DMZ | Reserved isolated services zone |

Kali Linux runs outside the Proxmox infrastructure in VirtualBox.

This placement represents an external attacker and forces the relevant traffic to pass through the OPNsense perimeter.

OPNsense controls communication between the zones and applies a default-deny security model.

---

# Virtual Infrastructure

![Proxmox Lab](assets/proxmox-lab.png)

The internal environment contains:

| System | Function |
|---|---|
| OPNsense | Firewall, router and network segmentation |
| Wazuh Server | Centralized security monitoring |
| Windows 11 | User workstation and attack target |

Kali Linux runs separately in VirtualBox on the physical workstation.

Detailed deployment information:

- [Proxmox setup](setup/proxmox.md)
- [Proxmox network configuration](configs/proxmox/interfaces.example)

---

# Network Segmentation

![OPNsense VLANs](assets/opnsense-vlans.png)

The network is segmented to reduce unnecessary communication and approximate the separation commonly found in a company environment.

| Segment | Role |
|---|---|
| Management | Administrative access |
| SOC | Wazuh and defensive services |
| Users | Employee workstation |
| DMZ | Reserved isolated services |
| WAN | ISP network and external attacker |

Segmentation ensures that every system cannot communicate freely with every other system.

For example:

- a user workstation cannot administer the firewall;
- an external system cannot directly reach the SOC network;
- the SOC receives endpoint and firewall logs without exposing unnecessary services;
- management interfaces remain separated from user traffic.

Detailed configuration:

- [OPNsense setup](setup/opnsense.md)
- [OPNsense firewall rules](configs/opnsense/firewall-rules.example.md)

---

# Internet Gateway

The OPNsense WAN interface connects the lab to the ISP router.

```text
ISP router network: 192.168.1.0/24
ISP router gateway: 192.168.1.1
OPNsense WAN: 192.168.1.50
```

All internal networks use OPNsense as their gateway.

```text
Internal system
      ↓
OPNsense VLAN gateway
      ↓
OPNsense WAN
      ↓
ISP router
      ↓
Internet
```

This design separates the internal addressing plan from the ISP network.

When the ISP router or provider changes, only the OPNsense WAN configuration needs to be adapted. The internal VLANs, Wazuh server, Windows workstation and firewall policy can keep the same addressing plan.

---

# Firewall Policy

![OPNsense Firewall Rules](assets/opnsense-firewall-rules.png)

The firewall follows a default-deny approach.

Traffic is blocked unless a rule explicitly authorizes it.

Required communications include:

| Source | Destination | Purpose |
|---|---|---|
| Windows endpoint | Wazuh server | Agent registration and event forwarding |
| Windows endpoint | Internet | Updates and attack simulation |
| Management network | OPNsense | Firewall administration |
| Management network | Proxmox | Hypervisor administration |
| Wazuh server | Internet | Updates and package installation |

Prohibited communications include:

| Source | Destination | Result |
|---|---|---|
| WAN | SOC network | Blocked |
| Users network | Management network | Blocked |
| Users network | Firewall administration | Blocked |
| Unapproved VLANs | Internal services | Blocked |

The exact rules can be adapted to another addressing plan.

---

# SOC and Log Collection

![Wazuh Dashboard](assets/wazuh-dashboard.png)

Wazuh acts as the central security monitoring platform.

It collects and analyzes:

- Windows Event Logs;
- Sysmon process creation events;
- command-line arguments;
- network connections;
- file creation;
- scheduled-task activity;
- firewall events;
- custom LOTL detections.

The objective is not only to collect logs but to transform relevant activity into actionable security alerts.

Detailed configuration:

- [Wazuh setup](setup/wazuh.md)
- [Wazuh agent configuration](configs/wazuh/agent.conf)
- [Custom Wazuh rules](configs/wazuh/local_rules.xml)

---

## Endpoint Enrollment

![Wazuh Agents](assets/wazuh-agents.png)

The Windows workstation is enrolled as a Wazuh agent.

Sysmon provides more detailed endpoint telemetry than the default Windows logs alone.

This allows the SOC to observe:

- process images;
- parent and child processes;
- complete command lines;
- file creation;
- network destinations;
- scheduled-task operations;
- relationships between multiple events.

Detailed endpoint installation:

- [Windows setup](setup/windows.md)

---

# Attack Scenario

The attack scenario uses legitimate Windows binaries instead of a traditional malware executable.

The binaries were selected by researching their documented abuse capabilities through the LOLBAS project.

The scenario is composed of three behaviours:

1. payload retrieval;
2. command execution;
3. persistence creation.

This demonstrates why executable reputation alone is insufficient.

A trusted binary may still perform a malicious action depending on its command line, destination and execution context.

---

## Kali Linux

Kali Linux runs in VirtualBox on the physical workstation and represents an external attacker outside the Proxmox environment.

```text
Platform: VirtualBox
Network mode: Bridged Adapter
IP address: 192.168.1.30
Network: ISP router LAN
```

Kali is used to:

- host the benign test payload;
- simulate the external source;
- validate firewall behaviour;
- generate activity monitored by Wazuh.

---

## Payload Hosting

![Kali Payload Server](assets/payload_kali.png)

The payload is stored in:

[`scripts/payload.py`](scripts/payload.py)

The payload is intentionally benign. It only displays the execution time and the hostname of the Windows workstation.

```python
import datetime
import socket

print(f"[+] Simulated compromise at {datetime.datetime.now()}")
print(f"[+] Hostname: {socket.gethostname()}")
```

On Kali, place the payload in the working
