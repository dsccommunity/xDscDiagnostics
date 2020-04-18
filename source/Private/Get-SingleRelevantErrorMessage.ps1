function Get-SingleRelevantErrorMessage(<#[System.Diagnostics.Eventing.Reader.EventRecord]#>$errorEvent)
{
    $requiredPropertyIndex = @{
        4116 = 2;
        4131 = 1;
        4183 = -1; #means full message
        4129 = -1;
        4192 = -1;
        4193 = -1;
        4194 = -1;
        4185 = -1;
        4097 = 6;
        4103 = 5;
        4104 = 4
    }
    $cimErrorId = 4131
    $errorText = ""
    $outputErrorMessage = ""
    $eventId = $errorEvent.Id
    $propertyIndex = $requiredPropertyIndex[$eventId]
    if ($propertyIndex -ne -1)
    {

        #This means You need just the property from the indices hash
        $outputErrorMessage = $errorEvent.Properties[$propertyIndex].Value

    }
    else
    {
        $outputErrorMessage = Get-MessageFromEvent -EventRecord $errorEvent
    }
    return $outputErrorMessage

}
