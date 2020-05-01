function Get-AllGroupedDscEvents
{
    $groupedEvents = $null
    $latestEvent = Get-LatestEvent
    LogDscDiagnostics -Verbose "Collecting all events from the DSC logs"
    if ($script:LatestEvent[$script:ThisComputerName])
    {
        #Check if there were any differences between the latest event and the latest event in th ecache
        $compareResult = Compare-Object $script:LatestEvent[$script:ThisComputerName] $latestEvent -Property TimeCreated, Message
        #Compare object result will be null if they're both equal
        if (($compareResult -eq $null) -and $script:LatestGroupedEvents[$script:ThisComputerName])
        {
            # this means no new events were generated and you can use the event cache.
            $groupedEvents = $script:LatestGroupedEvents[$script:ThisComputerName]
            return $groupedEvents
        }

    }
    #if cache needs to be replaced, it will not return in the previous line and will come here.

    #Save it to cache
    $allEvents = Get-AllDscEvents
    if (!$allEvents)
    {
        LogDscDiagnostics -Error "Error : Could not find any events. Either a DSC operation has not been run, or the event logs are turned off . Please ensure the event logs are turned on in DSC. To set an event log, run the command wevtutil Set-Log <channelName> /e:true, example: wevtutil set-log 'Microsoft-Windows-Dsc/Operational' /e:true /q:true"
        return
    }
    $groupedEvents = $allEvents | Group-Object {
        $_.Properties[0].Value
    }

    $script:LatestEvent[$script:ThisComputerName] = $latestEvent
    $script:LatestGroupedEvents[$script:ThisComputerName] = $groupedEvents


    #group based on their Job Ids
    return $groupedEvents
}
