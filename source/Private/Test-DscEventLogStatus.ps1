#  Function to prompt the user to set an event log, for the channel passed in as parameter
function Test-DscEventLogStatus
{
    param ($Channel = "Analytic")
    $LogDetails = Get-WinEvent -ListLog "$script:DscLogName/$Channel"
    if ($($LogDetails.IsEnabled))
    {
        return $true
    }
    LogDscDiagnostics -Warning "The $Channel log is not enabled. To enable it, please run the following command: `n        Update-xDscEventLogStatus -Channel $Channel -Status Enabled `nFor more help on this cmdlet run Get-Help Update-xDscEventLogStatus"

    return $false
}
