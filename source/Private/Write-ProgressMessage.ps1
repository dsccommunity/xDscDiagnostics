function Write-ProgressMessage
{
    [CmdletBinding()]
    param ([string]$Status, [int]$PercentComplete, [switch]$Completed)

    Write-Progress -Activity 'Get-AzureVmDscDiagnostics' @PSBoundParameters
    Write-Verbose -message $status
}
