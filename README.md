# Company-Style SOC Homelab — Detecting Living Off the Land Attacks

> A reusable Blue Team homelab designed to approximate the segmented infrastructure and security monitoring capabilities found in a small company.

![Lab Architecture](assets/architecture.png)

---

## Project Purpose

Living Off the Land attacks abuse legitimate tools already available on a compromised operating system.

Instead of introducing an obvious malicious executable, an attacker can use trusted Windows binaries for actions such as:

- downloading files;
- executing commands;
- establishing persistence;
- bypassing basic security controls.

Because these binaries are also used for legitimate administration, detecting malicious usage requires more context than simply identifying the executable name.

This project was created to study that problem from a Blue Team perspective.

The objective was to build a homelab approaching what a small company security environment could look like, including:

- a virtualized infrastructure;
- separated network zones;
- centralized security monitoring;
- Windows endpoint telemetry;
- firewall logging;
- custom behavioural detection rules;
- incident investigation;
- containment and endpoint hardening.

The Windows binaries used in the attack scenario were selected through the [LOLBAS project](https://lolbas-project.github.io/), which documents legitimate Microsoft-signed binaries and scripts that can be abused during offensive operations.

The implemented scenario demonstrates how legitimate Windows components can be combined into a simple attack chain and how a SOC can detect the resulting behaviour.

This is not intended to reproduce a complete production SOC. It is a compact and reusable environment for learning, testing detection rules and experimenting with defensive controls.

---

## Repository Design

The repository is structured so that the complete project can be understood directly from this README.

Detailed configuration files and scripts are stored separately so they can be copied, modified and reused without extracting them from the documentation.

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

### Directory roles

| Directory | Content |
|---|---|
| `assets/` | Architecture diagrams and project screenshots |
| `configs/` | Reusable configuration files for Wazuh, Windows, OPNsense and Proxmox |
| `docs/` | Troubleshooting notes, lessons learned, references and roadmap |
| `scripts/` | Attack simulation, containment and hardening scripts |
| `setup/` | Detailed installation notes for individual components |

All core configurations used by the lab are intended to be provided in this repository.

The project can therefore be reproduced as documented or used as a foundation for a different environment. Network ranges, detection rules, response mechanisms and attack scenarios can all be adapted or extended.

---

## What This Lab Demonstrates

The project covers a complete defensive workflow:

1. Build a company-style virtual infrastructure.
2. Separate systems into different security zones.
3. Control communications through a firewall.
4. Centralize endpoint and network telemetry.
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
| Management | Administration of the infrastructure |
| SOC | Security monitoring and log analysis |
| Users | Windows endpoint environment |
| WAN | External attacker simulation |
| DMZ | Reserved isolated services zone |

The Kali system is placed outside the internal virtual network to simulate activity originating from an external source.

OPNsense controls communication between the zones and applies a default-deny security model.

---

# Virtual Infrastructure

![Proxmox Lab](assets/proxmox-lab.png)

The main systems are:

| System | Function |
|---|---|
| OPNsense | Firewall, router and network segmentation |
| Wazuh Server | Centralized security monitoring |
| Windows 11 | User workstation and attack target |
| Kali Linux | External attack workstation |

Proxmox provides the virtual switches and interfaces required to connect each machine to the correct network segment.

Detailed deployment notes:

- [Proxmox setup](setup/proxmox.md)
- [Proxmox configuration files](configs/proxmox/)

---

# Network Segmentation

![OPNsense VLANs](assets/opnsense-vlans.png)

The network is segmented to reduce unnecessary communication between systems and to approximate the separation commonly found in a company environment.

Example segmentation:

| Segment | Example role |
|---|---|
| Management | Administrative access |
| SOC | Wazuh and defensive services |
| Users | Employee workstations |
| DMZ | Exposed or isolated services |
| WAN | External networks |

Segmentation prevents every machine from communicating freely with every other system.

For example:

- a user workstation should not administer the firewall;
- an external system should not directly reach the SOC network;
- the SOC should receive logs without exposing unnecessary services;
- management interfaces should remain isolated from user traffic.

Detailed configuration:

- [OPNsense setup](setup/opnsense.md)
- [OPNsense configuration files](configs/opnsense/)

---

# Firewall Policy

![OPNsense Firewall Rules](assets/opnsense-firewall-rules.png)

The firewall policy follows a default-deny approach.

Traffic is blocked unless a rule explicitly authorizes it.

Examples of required communications include:

| Source | Destination | Purpose |
|---|---|---|
| Windows endpoint | Wazuh server | Agent registration and event forwarding |
| Windows endpoint | Internet | Required web access |
| Management network | OPNsense | Firewall administration |
| Management network | Proxmox | Hypervisor administration |
| Wazuh server | External repositories | Updates and package installation |

Examples of prohibited communications include:

| Source | Destination | Result |
|---|---|---|
| WAN | SOC network | Blocked |
| User network | Management network | Blocked |
| User network | Firewall administration | Blocked |
| Unapproved VLANs | Internal services | Blocked |

The exact rules depend on the network ranges used during deployment and can be adapted to another environment.

---

# SOC and Log Collection

![Wazuh Dashboard](assets/wazuh-dashboard.png)

Wazuh acts as the central security monitoring platform.

It collects and analyzes telemetry from the Windows endpoint and other infrastructure components.

The monitored data includes:

- Windows Event Logs;
- Sysmon process creation events;
- command-line arguments;
- network connections;
- scheduled task creation;
- authentication activity;
- firewall events;
- custom Wazuh detections.

The purpose is not only to collect logs but to transform relevant events into actionable security alerts.

Detailed configuration:

- [Wazuh setup](setup/wazuh.md)
- [Wazuh configuration files](configs/wazuh/)

---

## Endpoint Enrollment

![Wazuh Agents](assets/wazuh-agents.png)

The Windows workstation is enrolled as a Wazuh agent.

Sysmon is installed on the endpoint to provide more detailed telemetry than the default Windows logs alone.

This allows the SOC to observe:

- the executable that started a process;
- its parent process;
- the complete command line;
- file creation;
- network destinations;
- scheduled task operations;
- relationships between multiple events.

Detailed endpoint configuration:

- [Windows setup](setup/windows.md)
- [Windows and Sysmon configurations](configs/windows/)

---

# Attack Scenario

The attack scenario uses legitimate Windows binaries instead of a traditional malware executable.

The binaries were selected by researching their documented abuse capabilities through the LOLBAS project.

The objective is to reproduce a simple Living Off the Land chain composed of three behaviours:

1. payload retrieval;
2. command execution;
3. persistence creation.

This approach demonstrates why monitoring only executable reputation is insufficient. A trusted binary may still perform a malicious action depending on its command line, parent process, destination and execution context.

---

## Payload Hosting

![Kali Payload Server](assets/payload_kali.png)

Kali Linux hosts the test payload through a Python HTTP server.

This creates a controlled external source from which the Windows endpoint can retrieve the file.

The payload is intentionally simple. The objective is to generate observable behaviour for the SOC, not to develop stealth malware.

Relevant files:

- [Kali setup](setup/kali.md)
- [`payload.py`](scripts/payload.py)

---

## Living Off the Land Kill Chain

![LOTL Kill Chain](assets/killchain.png)

The attack chain uses the following Windows components:

| Binary | Role in the scenario |
|---|---|
| `certutil.exe` | Downloads the payload from the Kali server |
| `conhost.exe` | Participates in command execution |
| `schtasks.exe` | Creates scheduled-task persistence |

### Stage 1 — Payload retrieval

`certutil.exe` is a legitimate Windows certificate utility.

In this scenario, its file-download capability is abused to retrieve content from the external Kali server.

The binary itself is trusted. The suspicious elements are its arguments, destination and execution context.

### Stage 2 — Execution

The downloaded content is executed through native Windows command-processing components.

The SOC observes the related process tree and command-line activity through Sysmon.

### Stage 3 — Persistence

`schtasks.exe` creates a scheduled task so that the command can be executed again later.

Scheduled tasks are frequently used legitimately by administrators and software installers. Detection must therefore focus on unusual task names, executable paths, users and command arguments.

---

# Detection Engineering

The default event collection produced useful telemetry but did not provide a complete high-level alert for the full scenario.

Custom Wazuh rules were therefore created to detect the individual attack stages and correlate them.

![Wazuh Initial Alerts](assets/wazuh-pre-alerts.png)

Example detection logic:

| Rule ID | Behaviour |
|---|---|
| `100001` | Suspicious `certutil` download activity |
| `100002` | Suspicious execution involving `conhost` |
| `100003` | Scheduled-task persistence |
| `100010` | Correlated LOTL kill chain |

The rules analyze contextual fields such as:

- process image;
- parent process;
- command line;
- event identifier;
- user account;
- execution sequence;
- previous matching alerts.

The rules are available in:

- [Wazuh detection configuration](configs/wazuh/)
- [Wazuh setup and rule explanation](setup/wazuh.md)

---

## Correlation

Detecting one legitimate binary is not sufficient to confirm an attack.

For example:

- `certutil.exe` may be used for certificate administration;
- `schtasks.exe` may be used for normal system maintenance;
- `conhost.exe` is part of standard Windows command execution.

The confidence level increases when several suspicious behaviours occur on the same endpoint within a limited time window.

The correlation rule combines the separate detections into a higher-level alert representing the complete attack chain.

This reduces the need for an analyst to manually connect every low-level event.

---

# MITRE ATT&CK Mapping

![MITRE ATT&CK Mapping](assets/mitre-mapping.png)

The detections are mapped to MITRE ATT&CK techniques to provide a standardized description of the observed behaviour.

The mapping helps an analyst answer:

- what the attacker attempted;
- which phase of the intrusion was observed;
- which systems were affected;
- which defensive controls detected the activity;
- where additional coverage may be required.

The exact technique identifier depends on the behaviour detected rather than only the binary name.

---

# Investigation

Once the alerts are generated, the analyst can reconstruct the sequence of events from the Wazuh dashboard.

The investigation process includes:

1. identifying the affected endpoint;
2. reviewing the triggering command lines;
3. examining parent and child processes;
4. identifying the external source address;
5. checking the downloaded file path;
6. verifying whether persistence was created;
7. confirming the chronological relationship between events.

The lab demonstrates that the most useful evidence often comes from combining several telemetry sources rather than relying on one alert in isolation.

---

# Containment Demonstration

![CrowdSec Ban](assets/crowdsec-ban.png)

CrowdSec was used to demonstrate source-IP containment.

In this lab, the ban was not triggered automatically by the Wazuh correlation rule. The source address was identified during the investigation and then blocked as a containment action.

This is an important distinction:

- **detection** was performed by Wazuh;
- **analysis** identified the attack source;
- **containment** was demonstrated through CrowdSec;
- **full response automation was not implemented**.

In a company environment, an EDR, SOAR platform, firewall API or Wazuh active-response workflow could automate similar actions after sufficient validation.

Automatic containment would need safeguards to avoid blocking legitimate systems because of a false positive.

Relevant script:

- [`crowdsec-ban.sh`](scripts/crowdsec-ban.sh)

---

# Endpoint Hardening

![Certutil Blocked](assets/certutil-bloquer.png)

After the incident, the endpoint configuration was hardened to prevent the original download method from succeeding again.

The objective was not to claim that one rule prevents every Living Off the Land attack.

Blocking or restricting a single binary only mitigates one specific path. An attacker may attempt another trusted binary or execution method.

Effective remediation therefore combines:

- application control;
- least privilege;
- restricted administrative tools;
- process and command-line monitoring;
- network egress filtering;
- updated detection rules;
- continued validation.

Relevant script:

- [`hardening.ps1`](scripts/hardening.ps1)

---

# Validation After Remediation

![Wazuh Alerts After Remediation](assets/wazuh-alerts.png)

The attack was executed again after the defensive changes.

The purpose of this second test was to verify whether:

- the original payload retrieval method still worked;
- the endpoint generated the expected telemetry;
- the SOC continued to receive events;
- the detection rules remained functional;
- the remediation changed the result of the attack.

This validation step is essential. A remediation should not be considered effective only because a policy was created; it must be tested against the original scenario.

---

# Reproducing the Lab

The recommended deployment order is:

```text
1. Install Proxmox VE
2. Create the virtual networks
3. Deploy OPNsense
4. Configure VLANs and firewall rules
5. Deploy the Wazuh server
6. Deploy the Windows endpoint
7. Install Sysmon
8. Install and enroll the Wazuh agent
9. Prepare the Kali attack workstation
10. Import the custom Wazuh rules
11. Execute the attack scenario
12. Analyze the generated alerts
13. Apply containment and hardening
14. Repeat the test
```

Detailed component pages:

| Component | Documentation | Reusable files |
|---|---|---|
| Proxmox | [Setup guide](setup/proxmox.md) | [Configurations](configs/proxmox/) |
| OPNsense | [Setup guide](setup/opnsense.md) | [Configurations](configs/opnsense/) |
| Wazuh | [Setup guide](setup/wazuh.md) | [Configurations](configs/wazuh/) |
| Windows | [Setup guide](setup/windows.md) | [Configurations](configs/windows/) |
| Kali | [Setup guide](setup/kali.md) | [`payload.py`](scripts/payload.py) |

The README contains the full project workflow. The individual setup pages are intended for commands, screenshots and configuration details that would otherwise make the main page unnecessarily difficult to navigate.

---

# Reusable Files

Planned reusable content includes:

```text
configs/
├── opnsense/
│   └── firewall and network configuration
│
├── proxmox/
│   └── virtual network configuration
│
├── wazuh/
│   ├── local_rules.xml
│   ├── agent configuration
│   └── decoder or integration files
│
└── windows/
    ├── Sysmon configuration
    └── endpoint logging configuration
```

```text
scripts/
├── payload.py
├── crowdsec-ban.sh
└── hardening.ps1
```

Configuration values such as interfaces, usernames, IP addresses and network ranges may need to be adapted before reuse.

---

# Limitations

This project is a homelab and does not reproduce every capability of a production SOC.

Current limitations include:

- no high-availability architecture;
- no complete Active Directory environment;
- no production EDR;
- no automated case-management workflow;
- no fully automated containment pipeline;
- a limited number of endpoints;
- one primary LOTL attack scenario;
- simplified payload and persistence mechanisms.

These limitations are documented intentionally so that the demonstrated capabilities are not overstated.

---

# Possible Extensions

The lab can be extended with:

- Active Directory;
- additional Windows endpoints;
- Linux servers;
- Suricata IDS/IPS;
- a production-style EDR;
- Sigma rule conversion;
- MISP threat intelligence;
- vulnerability management;
- SOAR integration;
- automated Wazuh active response;
- additional LOLBAS scenarios;
- PowerShell abuse detection;
- lateral movement simulations;
- centralized case management.

The repository is designed to serve as a reusable foundation rather than a fixed final architecture.

---

# Lessons Demonstrated

This project highlights several defensive principles:

- trusted binaries can still perform malicious actions;
- executable reputation alone is insufficient;
- command-line telemetry is critical;
- segmentation limits unnecessary exposure;
- correlation improves detection confidence;
- automated response must account for false positives;
- remediation must be tested;
- one blocked technique does not eliminate the broader threat;
- reusable configurations make a lab easier to reproduce and improve.

---

# Disclaimer

This project is intended for defensive education and controlled laboratory use.

All attack simulations should be performed only on systems and networks you own or are explicitly authorized to test.
