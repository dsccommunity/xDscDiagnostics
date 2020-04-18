function Get-MessageFromEvent($EventRecord , [switch]$verboseType)
{
    #You need to remove the job ID and send back the message
    if ($EventRecord.Id -in $script:DscVerboseEventIdsAndPropertyIndex.Keys -and $verboseType)
    {
        $requiredIndex = $script:DscVerboseEventIdsAndPropertyIndex[$($EventRecord.Id)]
        return $EventRecord.Properties[$requiredIndex].Value
    }

    $NonJobIdText = ($EventRecord.Message -split ([Environment]::NewLine , 2))[1]


    return $NonJobIdText
}
