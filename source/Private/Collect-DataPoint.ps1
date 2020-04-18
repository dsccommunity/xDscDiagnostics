# attempts to Collect a datapoint
# Returns $true if it believes it collected the datapoint
function Collect-DataPoint
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [String] $Name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [HashTable] $dataPoint,

        [Parameter(Mandatory = $true)]
        [HashTable] $invokeCommandParams
    )

    $collected = $false
    if ($dataPoint.ScriptBlock)
    {
        Write-Verbose -Message "Collecting '$name-$($dataPoint.Description)' using ScripBlock ..."
        Invoke-Command -ErrorAction:Continue @invokeCommandParams -script $dataPoint.ScriptBlock -argumentlist @($tempPath)
        $collected = $true
    }

    if ($dataPoint.EventLog)
    {
        Write-Verbose -Message "Collecting '$name-$($dataPoint.Description)' using Eventlog ..."
        try
        {
            Export-EventLog -Name $dataPoint.EventLog -Path $tempPath @invokeCommandParams
        }
        catch
        {
            Write-Warning "Collecting '$name-$($dataPoint.Description)' failed with the following error:$([System.Environment]::NewLine)$_"
        }

        $collected = $true
    }
    return $collected
}
