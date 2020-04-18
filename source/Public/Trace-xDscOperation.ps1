<#
.SYNOPSIS
Traces through any DSC operation selected from among all operations using its unique sequence ID (obtained from Get-xDscOperation), or from its unique Job ID

.DESCRIPTION
This function, when called, will look through all the event logs for DSC, and output the results in the form of an object, that contains the event type, event message, time created, computer name, job id, sequence number, and the event information.

.PARAMETER SequenceId
Each operation in DSC has a certain Sequence ID, ordered by time of creation of these DSC operations. The sequence IDs can be obtained by running Get-xDscOperation
By mentioning a sequence ID, the trace of the corresponding DSC operation is output.

.PARAMETER JobId
The event viewer shows each DSC event start with a unique job ID for each operation. If this job id is specified with this parameter, then all diagnostic messages displayed are taken from the dsc operation pertaining to this job id.

.PARAMETER ComputerName
The names of computers in which you would like to trace the past DSC operations

.PARAMETER Credential
The credential needed to access the computers specified inside ComputerName parameters

.EXAMPLE
Trace-xDscOperation
To Obtain the diagnostic information for the latest operation

.EXAMPLE
Trace-xDscOperation -sequenceId 3
To obtain the diagnostic information for the third latest operation

.EXAMPLE
Trace-xDscOperation -JobId 11112222-1111-1122-1122-111122221111
To diagnose an operation with job Id 11112222-1111-1122-1122-111122221111

.EXAMPLE
Trace-xDscOperation -ComputerName XYZ -sequenceID 2
To Get Logs from a remote computer

.EXAMPLE
Trace-xDscOperation -Computername XYZ -Credential $mycredential -sequenceID 2

To Get logs from a remote computer with credentials

.EXAMPLE
Trace-xDscOperation -ComputerName @("PN25113D0891", "PN25113D0890")

To get logs from multiple remote computers

.NOTES
Please note that to perform actions on the remote computer, have the firewall for remote configuration enabled. This can be done with the following command:

New-NetFirewallRule -Name "Service RemoteAdmin" -Action Allow
#>
function Trace-xDscOperation
{

    [cmdletBinding()]
    param(
        [UInt32]$SequenceID = 1, #latest is by default
        [Guid]$JobId,
        [String[]]$ComputerName,
        [pscredential]$Credential)
    Add-ClassTypes
    if ($ComputerName)
    {
        $script:UsingComputerName = $true
        $args = $PSBoundParameters
        $null = $args.Remove("ComputerName")
        $null = $args.Remove("Credential")

        foreach ($thisComputerName in $ComputerName)
        {
            LogDscDiagnostics -Verbose "Gathering logs for Computer $thisComputerName ..."
            $script:ThisComputerName = $thisComputerName
            $script:ThisCredential = $Credential
            Trace-DscOperationInternal  @PSBoundParameters

        }
    }
    else
    {
        $script:ThisComputerName = $env:COMPUTERNAME
        Trace-DscOperationInternal @PSBoundParameters
        $script:UsingComputerName = $false
    }
}
