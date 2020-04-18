<#
.SYNOPSIS
Sets any DSC Event log (Operational, analytic, debug )

.DESCRIPTION
This cmdlet will set a DSC log when run with Update-xDscEventLogStatus <channel Name>.

.PARAMETER Channel
Mandatory parameter : Name of the channel of the event log to be set - It has to be one of Operational, Analytic or debug

.PARAMETER Status
Mandatory Parameter : This is a string parameter which is either "Enabled" or "disabled" representing the required final status of the log channel. If this value is "enabled", then the channel is enabled.

.PARAMETER ComputerName
String parameter that can be used to set the event log channel on a remote computer . Note : It may need a credential

.PARAMETER Credential
Credential to be passed in so that the operation can be performed on the remote computer

.EXAMPLE
C:\PS> Update-xDscEventLogStatus "Analytic" -Status "Enabled"

.EXAMPLE
C:\PS> Update-xDscEventLogStatus -Channel "Debug" -ComputerName "ABC"

.EXAMPLE
C:\PS> Update-xDscEventLogStatus -Channel "Debug" -ComputerName "ABC" -Status Disabled

#>
function Update-xDscEventLogStatus
{
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Analytic' , 'Debug' , 'Operational')]
        [String]$Channel,

        [Parameter(Mandatory)]
        [ValidateSet('Enabled' , 'Disabled')]
        [String]$Status,

        [String]$ComputerName,

        [PSCredential]$Credential
    )

    $LogName = "Microsoft-Windows-Dsc"
    $statusEnabled = $false
    $eventLogFullName = "$LogName/$Channel"
    if ($Status -eq "Enabled")
    {
        $statusEnabled = $true
    }
    #Form the basic command which will enable/disable any event log
    $commandToExecute = "wevtutil set-log $eventLogFullName /e:$statusEnabled /q:$statusEnabled   "

    LogDscDiagnostics -Verbose "Changing status of the log $eventLogFullName to $Status"
    #If there is no computer name specified, just invoke the command in the same computer
    if (!$ComputerName)
    {

        Invoke-Expression $commandToExecute
    }
    else
    {

        #For any other computer, invoke command.
        $scriptToSetChannel = [Scriptblock]::Create($commandToExecute)

        if ($Credential)
        {
            Invoke-Command -ScriptBlock $scriptToSetChannel -ComputerName $ComputerName  -Credential $Credential
        }
        else
        {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptToSetChannel
        }
    }

    LogDscDiagnostics -Verbose "The $Channel event log has been $Status. "
}
