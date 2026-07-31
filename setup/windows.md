# Windows Endpoint Setup

The Windows workstation represents a company endpoint monitored by the SOC.

It is connected to the Users VLAN and sends Windows and Sysmon events to the Wazuh server.

---

## Network Configuration

```text
Hostname: WIN-VICTIM
IP address: 10.10.20.20
Gateway: 10.10.20.1
DNS server: 10.10.20.1
VLAN: 20 — Users
Wazuh server: 10.10.10.40
```

Verify network connectivity:

```powershell
ping 10.10.20.1
```

```powershell
Test-NetConnection 10.10.10.40 -Port 1515
```

---

## Install Sysmon

Sysmon provides the telemetry required to detect the LOTL attack chain.

During the setup, several Sysmon configurations were tested because the initial event collection did not provide all the required telemetry.

The final deployment used the community configuration maintained by **SwiftOnSecurity**.

Download:

- Sysmon from Microsoft Sysinternals;
- `sysmonconfig-export.xml` from the SwiftOnSecurity Sysmon configuration repository.

Install Sysmon from an administrator PowerShell terminal:

```powershell
.\Sysmon64.exe -accepteula -i .\sysmonconfig-export.xml
```

Verify that the service is running:

```powershell
Get-Service Sysmon64
```

The expected status is:

```text
Running
```

The main events used by the lab are:

| Event ID | Activity |
|---:|---|
| `1` | Process creation |
| `3` | Network connection |
| `11` | File creation |
| `13` | Registry modification |
| `22` | DNS query |

To update an existing Sysmon installation with another configuration:

```powershell
.\Sysmon64.exe -c .\sysmonconfig-export.xml
```

---

## Install the Wazuh Agent

Install the Wazuh agent from an administrator terminal:

```cmd
msiexec.exe /i wazuh-agent-4.7.0-1.msi /q ^
WAZUH_MANAGER="10.10.10.40" ^
WAZUH_AGENT_NAME="WIN-VICTIM" ^
WAZUH_REGISTRATION_SERVER="10.10.10.40"
```

Start the service:

```cmd
NET START WazuhSvc
```

Verify it from PowerShell:

```powershell
Get-Service WazuhSvc
```

The endpoint should then appear as active in the Wazuh dashboard.

---

## Enable Sysmon Collection in Wazuh

Edit the local Wazuh agent configuration:

```text
C:\Program Files (x86)\ossec-agent\ossec.conf
```

Add the following block inside the main configuration:

```xml
<localfile>
  <location>Microsoft-Windows-Sysmon/Operational</location>
  <log_format>eventchannel</log_format>
</localfile>
```

A reusable snippet is available here:

[`configs/windows/ossec.conf.snippet`](../configs/windows/ossec.conf.snippet)

Restart the agent:

```powershell
Restart-Service WazuhSvc
```

---

## Verify Sysmon Events

Open Event Viewer:

```text
Applications and Services Logs
└── Microsoft
    └── Windows
        └── Sysmon
            └── Operational
```

Generate a test process:

```powershell
whoami
```

Then verify that process creation events are visible in Sysmon and Wazuh.

---

## Defender During Testing

Windows Defender was temporarily disabled during controlled attack testing when it interfered with the scenario.

This should only be done inside an isolated lab.

Re-enable the protection after testing:

```powershell
Set-MpPreference -DisableRealtimeMonitoring $false
```

The purpose of the lab is to study telemetry and detection, not to permanently operate an unprotected endpoint.

---

## Validation

Verify that:

- Windows uses the Users VLAN;
- the endpoint can reach OPNsense;
- the endpoint can reach the Wazuh server;
- Sysmon is running;
- the Wazuh agent is running;
- Sysmon Event ID 1 is generated;
- Sysmon events are visible in Wazuh;
- the endpoint appears active in the dashboard.

---

## Next Step

Continue with the external attack workstation:

[Kali Setup](kali.md)
