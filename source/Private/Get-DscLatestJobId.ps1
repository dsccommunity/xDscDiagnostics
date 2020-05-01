#Gets the JOB ID of the most recently executed script.
function Get-DscLatestJobId
{
    #Collect operational events , they're ordered from newest to oldest.

    $allEvents = Get-WinEvent -LogName "$script:DscLogName/operational" -MaxEvents 2 -ea Ignore
    if ($allEvents -eq $null)
    {
        return "NOJOBID"
    }
    $latestEvent = $allEvents[0] #Since it extracts it in a sorted order.

    #Extract just the jobId from the string like : Job : {<jobid>}
    #$jobInfo = (((($latestEvent.Message -split (":",2))[0] -split "job {")[1]) -split "}")[0]
    $jobInfo = $latestEvent.Properties[0].value

    return $jobInfo.ToString()
}
function Get-LatestEvent
{
    $allEvents = Get-WinEvent -LogName "$script:DscLogName/operational" -MaxEvents 2 -ea Ignore
    if ($allEvents -eq $null)
    {
        return "NOEVENT"
    }
    $latestEvent = $allEvents[0] #Since it extracts it in a sorted order.
    return $latestEvent
}
