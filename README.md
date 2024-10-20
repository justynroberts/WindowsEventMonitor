
# Windows Event Log Monitor with PagerDuty Integration

This PowerShell script monitors Windows Event Logs (**Application**, **Security**, and **System** by default) for errors, then sends alerts to PagerDuty. The alert includes detailed information, such as the event log name, host machine, current logged-in user, event source, and event message.

## Features
- Monitors Windows Event Logs (`Application`, `Security`, and `System`) for **Error** events.
- Sends an alert to PagerDuty with details like the host, logged-in user, event source, and message.
- Includes custom fields in PagerDuty alerts.
- Can be configured to monitor different logs or event levels.
  
## Prerequisites

### 1. PowerShell
Ensure that you have PowerShell installed. You can check the version by running the following command:

```powershell
$PSVersionTable.PSVersion
```

### 2. Administrative Privileges
- Running the script requires administrative privileges to read Windows Event Logs and register event sources.
- To ensure the script runs as Administrator, open PowerShell as **Administrator**.

### 3. PagerDuty Integration Key
To use this script, you need an **Events API v2** integration key from PagerDuty:
1. Log into your PagerDuty account.
2. Go to **Services** > **Service Directory** > **Create New Service** or use an existing service.
3. Add an **Events API v2** integration to the service and copy the **Integration Key**.

### 4. Event Source for Triggering Errors (Optional)
If you plan to trigger errors for testing, you may need to register an event source (done automatically in the script).

## Installation

1. Clone the repository or download the PowerShell script.

```bash
git clone https://github.com/yourusername/event-log-monitor.git
cd event-log-monitor
```

2. Edit the PowerShell script to include your **PagerDuty Integration Key**:

```powershell
$pagerDutyIntegrationKey = "YOUR_PAGERDUTY_INTEGRATION_KEY"
```

3. Ensure you have administrative privileges to run the script.

## Running the Script

### 1. Open PowerShell as Administrator
You need administrative rights to access event logs and send alerts.

### 2. Run the Script
Run the following command in PowerShell:

```powershell
.\event-log-monitor.ps1
```

The script will monitor the specified Windows event logs for new **Error** events and send an alert to PagerDuty whenever an error is detected.

### 3. Simulate an Error Event (Optional)
To simulate an error event for testing purposes, you can run the following PowerShell script that generates an error in the **Application** log:

```powershell
# Trigger an error event
$logName = "Application"
$eventSource = "TestEventSource"

# Ensure the event source exists; if not, create it
if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
    New-EventLog -LogName $logName -Source $eventSource
}

# Generate an error event with Event ID 1003
$eventID = 1003
$eventMessage = "This is a test error event to simulate an application failure."
Write-EventLog -LogName $logName -Source $eventSource -EventId $eventID -EntryType Error -Message $eventMessage

Write-Host "Error event written to the Application log."
```

### 4. Verifying PagerDuty Alerts
Once the script detects an error in the logs, it will send an alert to PagerDuty. You can view the alert in your PagerDuty dashboard.

## Configuration

You can modify the script to:
- **Change the logs being monitored**: By default, the script monitors the `Application`, `Security`, and `System` logs, but you can modify the `$logNamesToMonitor` array to include additional logs.
  
  Example:
  ```powershell
  $logNamesToMonitor = @("Application", "Security", "System", "CustomLogName")
  ```

- **Change the event level**: By default, the script only monitors **Error** level events. You can modify the `$eventLevel` variable to monitor other event levels like `Warning` or `Information`.

  Example:
  ```powershell
  $eventLevel = "Warning"
  ```

## Running the Script as a Windows Service

If you'd like to run this script as a Windows service to ensure continuous monitoring, you can use **NSSM** (Non-Sucking Service Manager) to create a service.

### Steps:

1. **Download NSSM**:
   - Download NSSM from [nssm.cc/download](https://nssm.cc/download).
   - Extract the downloaded file.

2. **Install the Script as a Service**:
   - Open an elevated command prompt (Run as Administrator).
   - Navigate to the folder where you extracted NSSM.
   
   Run the following command to install the service:

   ```bash
   nssm install EventLogMonitor
   ```

   A GUI will appear. Set the following fields:
   - **Path**: The full path to `powershell.exe`.
   - **Arguments**: The full path to your `event-log-monitor.ps1` script (include any required arguments).
   - **Startup Directory**: The directory where your script resides.

3. **Start the Service**:
   After the service is installed, start it with the following command:

   ```bash
   nssm start EventLogMonitor
   ```

4. **Verify the Service**:
   You can check if the service is running by opening **Services** (search for `services.msc` in the Start menu) and verifying that **EventLogMonitor** is running.

5. **To Stop/Remove the Service**:
   - Stop the service:
     ```bash
     nssm stop EventLogMonitor
     ```
   - Remove the service:
     ```bash
     nssm remove EventLogMonitor
     ```

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

---

### Contact
If you have any issues or questions, feel free to open an issue in the repository.
