# Define the event source and log
$logName = "Application"
$eventSource = "TestEventSource"

# Ensure the event source exists; if not, create it
if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
    New-EventLog -LogName $logName -Source $eventSource
}

# Generate an error event with Event ID 1003 and a custom message
$eventID = 1003
$eventMessage = "This is a test error event to simulate an application failure."

# Write the event to the Application log
Write-EventLog -LogName $logName -Source $eventSource -EventId $eventID -EntryType Error -Message $eventMessage

# Confirm the error was written
Write-Host "Error event with ID $eventID and message '$eventMessage' written to the $logName log."
