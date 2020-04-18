function Split-SingleDscGroupedRecord
{
    param(
        $singleRecordInGroupedEvents,
        $index)

    #$singleOutputRecord = New-Object psobject
    $status = $script:SuccessResult
    $errorEvents = @()
    $col_AllEvents = @()
    $col_verboseEvents = @()
    $col_analyticEvents = @()
    $col_debugEvents = @()
    $col_operationalEvents = @()
    $col_warningEvents = @()
    $col_nonVerboseEvents = @()

    #We want to now add a column for each event that says "staus as success or failure"
    $oneGroup = $singleRecordInGroupedEvents.Group
    $column_Time = $oneGroup[0].TimeCreated
    $oneGroup |
        % {
            $thisEvent = $_
            $thisType = ""
            $timeCreatedOfEvent = $_.TimeCreated

            if ($_.level -eq 2) #which means there's an error
            {
                $status = "$script:FailureResult"
                $errorEvents += $_
                $thisType = [Microsoft.PowerShell.xDscDiagnostics.EventType]::ERROR

            }
            elseif ($_.LevelDisplayName -like "warning")
            {
                $col_warningEvents += $_
            }
            if ($_.ContainerLog.endsWith("operational"))
            {
                $col_operationalEvents += $_ ;
                $col_nonVerboseEvents += $_

                #Only if its not an error message, mark it as OPerational tag
                if (!$thisType)
                {
                    $thisType = [Microsoft.PowerShell.xDscDiagnostics.EventType]::OPERATIONAL
                }
            }
            elseif ($_.ContainerLog.endsWith("debug"))
            {
                $col_debugEvents += $_ ; $thisType = [Microsoft.PowerShell.xDscDiagnostics.EventType]::DEBUG
            }
            elseif ($_.ContainerLog.endsWith("analytic"))
            {
                $col_analyticEvents += $_
                if ($_.Id -in $script:DscVerboseEventIdsAndPropertyIndex.Keys)
                {
                    $col_verboseEvents += $_
                    $thisType = [Microsoft.PowerShell.xDscDiagnostics.EventType]::VERBOSE

                }
                else
                {
                    $col_nonVerboseEvents += $_
                    $thisType = [Microsoft.PowerShell.xDscDiagnostics.EventType]::ANALYTIC

                }
            }
            $eventMessageFromEvent = Get-MessageFromEvent $thisEvent -verboseType
            #Add event with its tag

            $thisObject = New-Object PSobject -Property @{TimeCreated = $timeCreatedOfEvent; EventType = $thisType; Event = $thisEvent; Message = $eventMessageFromEvent }
            $defaultProperties = @('TimeCreated' , 'Message' , 'EventType')
            $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet' , [string[]]$defaultProperties)
            $defaultMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
            $thisObject | Add-Member MemberSet PSStandardMembers $defaultMembers

            $col_AllEvents += $thisObject

        }

    $jobIdWithoutParenthesis = ($($singleRecordInGroupedEvents.Name).split('{}'))[1] #Remove paranthesis that comes in the job id
    if (!$jobIdWithoutParenthesis)
    {
        $jobIdWithoutParenthesis = $null
    }

    $singleOutputRecord = New-Object Microsoft.PowerShell.xDscDiagnostics.GroupedEvents -property @{
        SequenceID     = $index;
        ComputerName   = $script:ThisComputerName;
        JobId          = $jobIdWithoutParenthesis;
        TimeCreated    = $column_Time;
        Result         = $status;
        NumberOfEvents = $singleRecordInGroupedEvents.Count;
    }

    $singleOutputRecord.AllEvents = $col_AllEvents | Sort-Object TimeCreated;
    $singleOutputRecord.AnalyticEvents = $col_analyticEvents ;
    $singleOutputRecord.WarningEvents = $col_warningEvents | Sort-Object TimeCreated ;
    $singleOutputRecord.OperationalEvents = $col_operationalEvents;
    $singleOutputRecord.DebugEvents = $col_debugEvents ;
    $singleOutputRecord.VerboseEvents = $col_verboseEvents  ;
    $singleOutputRecord.NonVerboseEvents = $col_nonVerboseEvents | Sort-Object TimeCreated;
    $singleOutputRecord.ErrorEvents = $errorEvents;

    return $singleOutputRecord
}
