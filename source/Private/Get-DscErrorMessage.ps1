function Get-DscErrorMessage
{
    param (<#[System.Diagnostics.Eventing.Reader.EventRecord[]]#>$ErrorRecords)
    $cimErrorId = 4131

    $errorText = ""
    foreach ($Record in $ErrorRecords)
    {
        #go through each record, and get the single error message required for that record.
        $outputErrorMessage = Get-SingleRelevantErrorMessage -errorEvent $Record
        if ($Record.Id -eq $cimErrorId)
        {
            $errorText = "$outputErrorMessage $errorText"
        }
        else
        {
            $errorText = "$errorText $outputErrorMessage"
        }
    }
    return  $errorText

}
