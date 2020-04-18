function Trace-DscOperationInternal
{
    [cmdletBinding()]
    param(
        [UInt32]$SequenceID = 1, #latest is by default
        [Guid]$JobId

    )


    #region VariableChecks
    $indexInArray = ($SequenceId - 1); #Since it is indexed from 0

    if ($indexInArray -lt 0)
    {
        LogDscDiagnostics -Error "Please enter a valid Sequence ID . All sequence IDs can be seen after running command Get-xDscOperation . " -ForegroundColor Red
        return
    }
    $null = Test-DscEventLogStatus -Channel "Analytic"
    $null = Test-DscEventLogStatus -Channel "Debug"

    #endregion

    #First get the whole object set of that operation
    $thisRUnsOutputEvents = ""
    if (!$JobId)
    {
        $thisRunsOutputEvents = Get-SingleDscOperation -IndexInArray $indexInArray
    }
    else
    {
        $thisRunsOutputEvents = Get-SingleDscOperation -IndexInArray $indexInArray -JobId $JobId
    }
    if (!$thisRunsOutputEvents)
    {
        return;
    }

    #Now we play with it.
    $result = $thisRunsOutputEvents.Result

    #Parse the error events and store them in error text.
    $errorEvents = $thisRunsOutputEvents.ErrorEvents
    $errorText = Get-DscErrorMessage -ErrorRecords  $errorEvents

    #Now Get all logs which are non verbose
    $nonVerboseMessages = @()

    $allEventMessageObject = @()
    $thisRunsOutputEvents.AllEvents |
        % {
            $ThisEvent = $_.Event
            $ThisMessage = $_.Message
            $ThisType = $_.EventType
            $ThisTimeCreated = $_.TimeCreated
            #Save a hashtable as a message value
            if (!$thisRunsOutputEvents.JobId)
            {
                $thisJobId = $null
            }
            else
            {
                $thisJobId = $thisRunsOutputEvents.JobId
            }
            $allEventMessageObject += New-Object Microsoft.PowerShell.xDscDiagnostics.TraceOutput -Property @{EventType = $ThisType; TimeCreated = $ThisTimeCreated; Message = $ThisMessage; ComputerName = $script:ThisComputerName; JobID = $thisJobId; SequenceID = $SequenceID; Event = $ThisEvent }

        }

    return $allEventMessageObject

}
