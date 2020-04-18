#Internal function called by Get-xDscOperation
function Get-DscOperationInternal
{
    param
    ([UInt32]$Newest = 10)
    #Groupo all events
    $groupedEvents = Get-AllGroupedDscEvents

    $DiagnosedGroup = $groupedEvents

    #Define the type that you want the output in

    $index = 1
    foreach ($singleRecordInGroupedEvents in $DiagnosedGroup)
    {
        $singleOutputRecord = Split-SingleDscGroupedRecord -singleRecordInGroupedEvents $singleRecordInGroupedEvents -index $index
        $singleOutputRecord
        if ($index -ge $Newest)
        {
            break;
        }
        $index++

    }
}
