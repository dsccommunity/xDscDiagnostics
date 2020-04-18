#
# Exports an event log to a file in the path specified
# on the specified session, if the session is not specified
# a session to the local machine will be used
#
function Export-EventLog
{
    [CmdletBinding()]
    param(
        [string] $Name,
        [string] $path,
        [System.Management.Automation.Runspaces.PSSession] $Session
    )
    Write-Verbose "Exporting eventlog $name"
    $local = $false
    $invokeCommandParams = @{ }
    if ($Session)
    {
        $invokeCommandParams.Add('Session', $Session);
    }
    else
    {
        $local = $true
    }

    invoke-command -ErrorAction:Continue @invokeCommandParams -script {
        param($name, $path)
        $ErrorActionPreference = 'stop'
        Set-StrictMode -Version latest
        Write-Debug "Name: $name"

        Write-Debug "Path: $path"
        Write-Debug "windir: $Env:windir"
        $exePath = Join-Path $Env:windir 'system32\wevtutil.exe'
        $exportFileName = "$($Name -replace '/','-').evtx"

        $ExportCommand = "$exePath epl '$Name' '$Path\$exportFileName' /ow:True 2>&1"
        Invoke-expression -command $ExportCommand
    } -argumentlist @($Name, $path)
}
