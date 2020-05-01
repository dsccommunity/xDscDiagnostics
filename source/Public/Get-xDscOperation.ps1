<#
.SYNOPSIS
Gives a list of all DSC operations that were executed . Each DSC operation has sequence Id information , and job id information
It returns a list of objects, each of which contain information on a distinct DSC operation . Here a DSC operation is referred to any single DSC execution, such as start-dscconfiguration, test-dscconfiguration etc. These will log events with a unique jobID (guid) identifying the DSC operation.

When you run Get-xDscOperation, you will see a list of past DSC operations , and you could use the following details from the output to trace any of them individually.
- Job ID : By using this GUID, you can search for the events in Event viewer, or run Trace-xDscOperation -jobID <required Jobid> to obtain all event details of that operation
- Sequence Id : By using this identifier, you could run Trace-xDscOperation <sequenceId> to get all event details of that particular dsc operation.


.DESCRIPTION
This will list all the DSC operations that were run in the past in the computer. By Default, it will list last 10 operations.

.PARAMETER Newest
By default 10 last DSC operations are pulled out from the event logs. To have more, you could use enter another number with this parameter.a PS Object with all the information output to the screen can be navigated by the user as required.


.EXAMPLE
Get-xDscOperation 20
Lists last 20 operations

.EXAMPLE
Get-xDscOperation -ComputerName @("XYZ" , "ABC") -Credential $cred
Lists operations for the array of computernames passed in.
#>

function Get-xDscOperation
{
    [cmdletBinding()]
    param
    (
        [UInt32]$Newest = 10,
        [String[]]$ComputerName,
        [pscredential]$Credential
    )
    Add-ClassTypes
    if ($ComputerName)
    {
        $script:UsingComputerName = $true
        $args = $PSBoundParameters
        $null = $args.Remove("ComputerName")
        $null = $args.Remove("Credential")

        foreach ($thisComputerName in $ComputerName)
        {
            LogDscDiagnostics -Verbose "Gathering logs for Computer $thisComputerName"
            $script:ThisComputerName = $thisComputerName
            $script:ThisCredential = $Credential
            Get-DscOperationInternal  @PSBoundParameters

        }
    }
    else
    {
        $script:ThisComputerName = $env:COMPUTERNAME
        Get-DscOperationInternal @PSBoundParameters
        $script:UsingComputerName = $false
    }
}
