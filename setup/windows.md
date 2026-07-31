# Windows Endpoint Setup

The Windows workstation represents the monitored company endpoint in the SOC-LOTL-Lab.

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

---

## Install Sysmon

Sysmon is used to collect the endpoint telemetry required for the LOTL detection rules.

The configuration was downloaded from the SwiftOnSecurity Sysmon configuration repository.

Download Sysmon from Microsoft Sysinternals, then download the SwiftOnSecurity configuration file.

Install Sysmon from an administrator terminal:

```powershell
.\Sysmon64.exe -accepteula -i .\sysmonconfig-export.xml
```

Verify that the service is running:

```powershell
Get-Service Sysmon64
```

The main events used by the lab are:

| Event ID | Activity |
|---:|---|
| `1` | Process creation |
| `3` | Network connection |
| `11` | File creation |
| `13` | Registry modification |
| `22` | DNS query |

---

## Install the Wazuh Agent

Install the Wazuh agent:

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

Verify the service:

```powershell
Get-Service WazuhSvc
```

The endpoint should then appear as active in the Wazuh dashboard.

---

## Configure Sysmon Event Collection

Edit:

```text
C:\Program Files (x86)\ossec-agent\ossec.conf
```

Add:

```xml
<localfile>
  <location>Microsoft-Windows-Sysmon/Operational</location>
  <log_format>eventchannel</log_format>
</localfile>
```

Restart the Wazuh agent:

```powershell
Restart-Service WazuhSvc
```

---

## Validation

Verify that:

- Sysmon is running;
- the Wazuh agent is running;
- the endpoint appears as active in Wazuh;
- Sysmon events are visible in the dashboard;
- process creation events include command-line information.
