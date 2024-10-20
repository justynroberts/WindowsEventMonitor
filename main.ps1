# Define the service integration key from PagerDuty
$pagerDutyIntegrationKey = "Enter your Key"
$pagerDutyApiUrl = "https://events.pagerduty.com/v2/enqueue"
# Configurable variables for logs to collect and event level
$logNamesToMonitor = @("Application", "Security", "System")   # Logs to collect
$eventLevel = "Error"                                         # Event level to monitor (e.g., Error, Warning, Information)
$pollingIntervalSeconds = 60                                  # Polling interval in seconds

# Function to get the current logged-in user
function Get-LoggedInUser {
    try {
        $user = (Get-WmiObject -Class Win32_ComputerSystem).UserName
        if (!$user) {
            $user = "N/A"  # If no user is logged in
        }
        return $user
    } catch {
        return "N/A"
    }
}

# Function to send a trigger event to PagerDuty
function Send-PagerDutyAlert {
    param (
        [string]$eventSummary,
        [string]$eventSource,
        [string]$logName,
        [string]$hostname,
        [string]$loggedInUser,  # Logged-in user
        [string]$eventTimeGenerated,
        [string]$eventComponent,
        [string]$eventClass,
        [string]$eventGroup,
        [string]$eventMessage  # Adding event message for custom_details
    )

    # Construct the payload with mandatory and custom fields
    $payload = @{
        routing_key  = $pagerDutyIntegrationKey
        event_action = "trigger"
        payload      = @{
            summary        = $eventSummary
            timestamp      = $eventTimeGenerated
            severity       = "error"  # Adjust this dynamically if needed (e.g., based on event type)
            source         = $hostname
            component      = $eventComponent
            group          = $eventGroup
            class          = $eventClass
            custom_details = @{
                Host          = $hostname       # Host included in custom details
                LoggedInUser  = $loggedInUser   # Add the logged-in user
                Log           = $logName
                EventSource   = $eventSource
                EventTime     = $eventTimeGenerated
                EventMessage  = $eventMessage  # Include the actual error message here
            }
        }
    }

    # Convert the payload to JSON
    $jsonPayload = $payload | ConvertTo-Json -Depth 3

    # Debug: Output the payload to verify its structure
    Write-Host "Sending Payload to PagerDuty:" -ForegroundColor Yellow
    Write-Host $jsonPayload

    # Send the HTTP request to PagerDuty
    try {
        $response = Invoke-RestMethod -Uri $pagerDutyApiUrl -Method Post -ContentType "application/json" -Body $jsonPayload
        Write-Host "PagerDuty alert sent successfully"
    } catch {
        Write-Host "Failed to send alert to PagerDuty: $($_.Exception.Message)"
    }
}

# Function to monitor new errors from a specific event log
function Monitor-WindowsEventLog {
    param (
        [string]$logName,
        [string]$eventLevel,
        [datetime]$lastCheckTime
    )

    # Query the event log for new events based on the specified level
    $newEvents = Get-EventLog -LogName $logName -EntryType $eventLevel -After $lastCheckTime

    if ($newEvents.Count -gt 0) {
        Write-Host "Found new event(s) in ${logName}: $($newEvents.Count)"
    } else {
        Write-Host "No new events in ${logName} since: $lastCheckTime"
    }

    foreach ($event in $newEvents) {
        $eventMessage = $event.Message
        $eventId = $event.EventID
        $eventSource = $event.Source
        $eventTimeGenerated = $event.TimeGenerated
        $hostname = $env:COMPUTERNAME
        $loggedInUser = Get-LoggedInUser  # Get the current logged-in user

        # Define custom fields for the event
        $eventSummary = "Log: ${logName} | Event ID: $eventId | Message: $eventMessage"
        $eventComponent = "Windows Event Log"
        $eventClass = "Error Event"
        $eventGroup = "System Monitoring"

        Write-Host "Processing Event ID: $eventId from ${logName}, Source: $eventSource"

        # Send an alert to PagerDuty for each new event with custom fields, including the event message and logged-in user
        Send-PagerDutyAlert -eventSummary $eventSummary -eventSource $eventSource -logName $logName `
                            -hostname $hostname -loggedInUser $loggedInUser -eventTimeGenerated $eventTimeGenerated `
                            -eventComponent $eventComponent -eventClass $eventClass -eventGroup $eventGroup `
                            -eventMessage $eventMessage  # Pass event message to custom_details

        # Log the event details (optional)
        Write-Host "Alert sent for event ID $eventId, Source: $eventSource, Time: $eventTimeGenerated"
    }

    # Return the latest event's time for future reference
    if ($newEvents.Count -gt 0) {
        return $newEvents | Sort-Object TimeGenerated -Descending | Select-Object -First 1 | ForEach-Object { $_.TimeGenerated }
    } else {
        return $lastCheckTime
    }
}

# Initialize last check time to the current time
$lastCheckTime = Get-Date

# Monitor the logs specified in the $logNamesToMonitor array
while ($true) {
    foreach ($logName in $logNamesToMonitor) {
        Write-Host "Checking ${logName} log..."
        $lastCheckTime = Monitor-WindowsEventLog -logName $logName -eventLevel $eventLevel -lastCheckTime $lastCheckTime
    }

    # Sleep for the specified polling interval
    Start-Sleep -Seconds $pollingIntervalSeconds
}
