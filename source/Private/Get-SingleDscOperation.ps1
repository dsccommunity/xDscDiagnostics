#This function gets all the DSC runs that are recorded into the event log.
function Get-SingleDscOperation
{
    #If you specify a sequence ID, then the diagnosis will be for that sequence ID.
    param(
        [Uint32]$indexInArray = 0,
        [Guid]$JobId
    )

    #Get all events
    $groupedEvents = Get-AllGroupedDscEvents
    if (!$groupedEvents)
    {
        return
    }
    #If there is a job ID present, ignore the IndexInArray, search based on jobID
    if ($JobId)
    {
        LogDscDiagnostics -Verbose "Looking at Event Trace for the given Job ID $JobId"
        $indexInArray = 0;
        foreach ($eventGroup in $groupedEvents)
        {

            #Check if the Job ID is present in any
            if ($($eventGroup.Name) -match $JobId)
            {
                break;
            }
            $indexInArray ++
        }
        if ($indexInArray -ge $groupedEvents.Count)
        {

            #This means the job id doesn't exist
            LogDscDiagnostics -Error "The Job ID Entered $JobId, does not exist among the dsc operations. To get a list of previously run DSC operations, run this command : Get-xDscOperation"
            return
        }
    }
    $requiredRecord = $groupedEvents[$indexInArray]
    if ($requiredRecord -eq $null)
    {
        LogDscDiagnostics -Error "Could not obtain the required record! "
        return
    }
    $errorText = "[None]"
    $thisRunsOutputEvents = Split-SingleDscGroupedRecord -singleRecordInGroupedEvents $requiredRecord -index $indexInArray

    $thisRunsOutputEvents
}
