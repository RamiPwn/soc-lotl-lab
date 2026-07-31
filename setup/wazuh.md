# Wazuh Setup

Wazuh is used as the central monitoring and detection platform of the SOC-LOTL-Lab.

It receives Windows and Sysmon events, applies custom detection rules and displays the resulting alerts in the dashboard.

![Wazuh Dashboard](../assets/wazuh-dashboard.png)

---

## Role in the Lab

Wazuh provides:

- centralized event collection;
- Windows endpoint monitoring;
- Sysmon event analysis;
- custom LOTL detection rules;
- event correlation;
- MITRE ATT&CK mapping.

The Wazuh server is connected to the SOC VLAN and uses a fixed IP address.

Example:

```text
Wazuh IP: <WAZUH_SERVER_IP>
Network: SOC VLAN
```

---

## Required Communications

The Windows endpoint must be able to reach the Wazuh server.

| Port | Protocol | Purpose |
|---:|---|---|
| 1514 | TCP | Agent event forwarding |
| 1515 | TCP | Agent enrollment |
| 55000 | TCP | Wazuh API, when required |
| 443 | TCP | Dashboard access, depending on installation |

The corresponding OPNsense rules must be placed above general inter-VLAN blocking rules.

---

## Agent Enrollment

Install the Wazuh agent on the Windows workstation using the package provided by the Wazuh dashboard.

Configure the manager address:

```text
<WAZUH_SERVER_IP>
```

Start the agent:

```powershell
Start-Service WazuhSvc
```

Verify its status:

```powershell
Get-Service WazuhSvc
```

The endpoint should then appear in the Wazuh dashboard.

![Wazuh Agents](../assets/wazuh-agents.png)

---

## Sysmon Event Collection

Sysmon records detailed endpoint activity such as:

- process creation;
- command-line arguments;
- parent processes;
- network connections;
- file creation;
- scheduled task activity.

The Wazuh agent collects the Sysmon event channel through the shared agent configuration:

[`configs/wazuh/agent.conf`](../configs/wazuh/agent.conf)

---

## Custom Detection Rules

The default event collection provides the telemetry required for investigation, but custom rules are used to identify the LOTL attack chain.

The rules detect:

| Rule ID | Behaviour |
|---|---|
| `100001` | Suspicious use of `certutil.exe` |
| `100002` | Suspicious execution involving `conhost.exe` |
| `100003` | Persistence using `schtasks.exe` |
| `100010` | Correlated LOTL attack chain |

The reusable rule file is available here:

[`configs/wazuh/local_rules.xml`](../configs/wazuh/local_rules.xml)

Copy it to the Wazuh manager:

```bash
/var/ossec/etc/rules/local_rules.xml
```

Then restart the manager:

```bash
sudo systemctl restart wazuh-manager
```

Check the service:

```bash
sudo systemctl status wazuh-manager
```

---

## Rule Testing

Wazuh rules can be tested before restarting the manager:

```bash
sudo /var/ossec/bin/wazuh-logtest
```

Paste a representative Sysmon event and verify that the expected rule is triggered.

The exact Sysmon field names may vary according to the Wazuh and Sysmon configuration. The rules may therefore require small adjustments after checking the raw event received by Wazuh.

---

## Detection Result

![Wazuh Alerts](../assets/wazuh-pre-alerts.png)

Each stage generates a separate alert.

The correlation rule creates a higher-level alert when the expected sequence is detected on the same endpoint within a limited period.

This is more reliable than considering the execution of one legitimate binary as malicious by itself.

---

## MITRE ATT&CK Mapping

![MITRE Mapping](../assets/mitre-mapping.png)

The custom rules include MITRE ATT&CK references to describe the observed behaviour.

The mapping is based on the action performed by the binary, not only on its executable name.

---

## Validation

Verify that:

- the Windows agent appears as active;
- Sysmon events reach Wazuh;
- process command lines are visible;
- the custom rules load without XML errors;
- `certutil`, `conhost` and `schtasks` activity generates alerts;
- the correlation rule generates the final LOTL alert.

Useful manager logs:

```bash
sudo tail -f /var/ossec/logs/ossec.log
```

Useful alerts file:

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.json
```

---

## Next Step

Continue with the Windows endpoint configuration:

[Windows Setup](windows.md)
