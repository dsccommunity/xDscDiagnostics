<####################################################################################################################################################
 #  This script enables a user to diagnose errors caused by a DSC operation. In short, the following commands would help you diagnose errors
 #  To get the last 10 operations in DSC that show their Result status (failure , success)         : Get-xDscOperation
 #  To get a list of last n (say, 13) DSC operations                                             : Get-xDscOperation -Newest 13
 #  To see details of the last operation                                                         : Trace-xDscOperation
 #  TO view trace details of the third last operation run                                        : Trace-xDscOperation 3
 #  To view trace details of an operation with Job ID $jID                                       : Trace-xDscOperation -JobID $jID
 #  To View trace details of multiple computers                                                  : Trace-xDscOperation -ComputerName @("PN25113D0891","PN25113D0890")
 #  To enable the debug event channel for DSC                                                    : Update-xDscEventLogStatus -Channel Debug -Status Enabled
 #  To enable the analytic event channel for DSC on another computer (say, with name ABC)        : Update-xDscEventLogStatus -Channel Analytic -Status Enabled -ComputerName ABC
 #  To disable the analytic event channel for DSC on another computer (say, with name ABC)       : Update-xDscEventLogStatus -Channel Analytic -Status Disabled -ComputerName ABC
 #####################################################################################################################################################>

#region Global variables
$script:DscVerboseEventIdsAndPropertyIndex = @{4100 = 3; 4117 = 2; 4098 = 3 };
$script:DscLogName = "Microsoft-windows-dsc"
$script:RedirectOutput = $false
$script:TemporaryHtmLocation = "$env:TEMP/dscreport"
$script:SuccessResult = "Success"
$script:FailureResult = "Failure"
$script:ThisCredential = ""
$script:ThisComputerName = $env:COMPUTERNAME
$script:UsingComputerName = $false
$script:FormattingFile = "xDscDiagnosticsFormat.ps1xml"
$script:RunFirstTime = $true
#endregion

#region Cache for events
$script:LatestGroupedEvents = @{ } #Hashtable of "Computername", "GroupedEvents"
$script:LatestEvent = @{ }          #Hashtable of "ComputerName", "LatestEvent logged"
#endregion

$script:azureDscExtensionTargetName = 'Azure DSC Extension'
$script:dscTargetName = 'DSC Node'
$script:windowsTargetName = 'Windows'
$script:dscPullServerTargetName = 'DSC Pull Server'
$script:validTargets = @($script:azureDscExtensionTargetName, $script:dscTargetName, $script:windowsTargetName, $script:dscPullServerTargetName)
$script:defaultTargets = @($script:azureDscExtensionTargetName, $script:dscTargetName, $script:windowsTargetName)

$script:datapointTypeName = 'xDscDiagnostics.DataPoint'
$script:dataPoints = @{
    AzureVmAgentLogs       = @{
        Description = 'Logs from the Azure VM Agent, including all extensions'
        Target      = $script:azureDscExtensionTargetName
        ScriptBlock = {
            param($tempPath)
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            Copy-Item -Recurse C:\WindowsAzure\Logs $tempPath\WindowsAzureLogs -ErrorAction SilentlyContinue
        }
    } # end data point
    DSCExtension           = @{
        Description = @'
The state of the Azure DSC Extension, including the configuration(s),
configuration data (but not any decryption keys), and included or
generated files.
'@
        Target      = $script:azureDscExtensionTargetName
        ScriptBlock = {
            param($tempPath)
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            $dirs = @(Get-ChildItem -Path C:\Packages\Plugins\Microsoft.Powershell.*DSC -ErrorAction SilentlyContinue)
            $dir = $null
            if ($dirs.Count -ge 1)
            {
                $dir = $dirs[0].FullName
            }

            if ($dir)
            {
                Write-Verbose -message "Found DSC extension at: $dir" -verbose
                Copy-Item -Recurse $dir $tempPath\DscPackageFolder -ErrorAction SilentlyContinue
                Get-ChildItem "$tempPath\DscPackageFolder" -Recurse | % {
                    if ($_.Extension -ieq '.msu' -or ($_.Extension -ieq '.zip' -and $_.BaseName -like 'Microsoft.Powershell*DSC_*.*.*.*'))
                    {
                        $newFileName = "$($_.FullName).wasHere"
                        Get-ChildItem $_.FullName | Out-String | Out-File $newFileName -Force
                        $_.Delete()
                    }
                }
            }
            else
            {
                Write-Verbose -message 'Did not find DSC extension.' -verbose
            }
        }
    } # end data point
    DscEventLog            = @{
        Description = 'The DSC event log.'
        EventLog    = 'Microsoft-Windows-DSC/Operational'
        Target      = $script:dscTargetName
    } # end data point
    ApplicationEventLog    = @{
        Description = 'The Application event log.'
        EventLog    = 'Application'
        Target      = $script:windowsTargetName
    } # end data point
    SystemEventLog         = @{
        Description = 'The System event log.'
        EventLog    = 'System'
        Target      = $script:windowsTargetName
    } # end data point
    PullServerEventLog     = @{
        Description = 'The DSC Pull Server event log.'
        EventLog    = 'Microsoft-Windows-PowerShell-DesiredStateConfiguration-PullServer/Operational'
        Target      = $script:dscPullServerTargetName
    } # end data point
    ODataEventLog          = @{
        Description = 'The Management OData event log (used by the DSC Pull Server).'
        EventLog    = 'Microsoft-Windows-ManagementOdataService/Operational'
        Target      = $script:dscPullServerTargetName
    } # end data point
    IisBinding             = @{
        Description = 'The Iis Bindings.'
        ScriptBlock = {
            param($tempPath)
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            $width = 900
            Get-WebBinding |
                Select-Object protocol, bindingInformation, sslFlags, ItemXPath |
                    Out-String -Width $width |
                        Out-File -FilePath $tempPath\IisBindings.txt -Width $width
        }
        Target      = $script:dscPullServerTargetName
    } # end data point
    HttpErrLogs            = @{
        Description = 'The HTTPERR logs.'
        ScriptBlock = {
            param($tempPath)
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            mkdir $tempPath\HttpErr > $null
            Copy-Item $env:windir\System32\LogFiles\HttpErr\*.* $tempPath\HttpErr -ErrorAction SilentlyContinue
        }
        Target      = $script:dscPullServerTargetName
    } # end data point
    IISLogs                = @{
        Description = 'The IIS logs.'
        ScriptBlock = {
            param($tempPath)
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            Import-Module WebAdministration
            $logFolder = (Get-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -name logfile.directory).Value
            mkdir $tempPath\Inetlogs > $null
            Copy-Item (Join-Path $logFolder *.*) $tempPath\Inetlogs -ErrorAction SilentlyContinue
        }
        Target      = $script:dscPullServerTargetName
    } # end data point
    ServicingLogs          = @{
        Description = 'The Windows Servicing logs, including, WindowsUpdate, CBS and DISM logs.'
        ScriptBlock = {
            param($tempPath)
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            mkdir $tempPath\CBS > $null
            mkdir $tempPath\DISM > $null
            Copy-Item $env:windir\WindowsUpdate.log $tempPath\WindowsUpdate.log -ErrorAction SilentlyContinue
            Copy-Item $env:windir\logs\CBS\*.* $tempPath\CBS -ErrorAction SilentlyContinue
            Copy-Item $env:windir\logs\DISM\*.* $tempPath\DISM -ErrorAction SilentlyContinue
        }
        Target      = $script:windowsTargetName
    } # end data point
    HotfixList             = @{
        Description = 'The output of Get-Hotfix'
        ScriptBlock = {
            param($tempPath)
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            Get-HotFix | Out-String | Out-File  $tempPath\HotFixIds.txt
        }
        Target      = $script:windowsTargetName
    } # end data point
    GetLcmOutput           = @{
        Description = 'The output of Get-DscLocalConfigurationManager'
        ScriptBlock = {
            param($tempPath)
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            $dscLcm = Get-DscLocalConfigurationManager
            $dscLcm | Out-String | Out-File   $tempPath\Get-dsclcm.txt
            $dscLcm | ConvertTo-Json -Depth 10 | Out-File   $tempPath\Get-dsclcm.json
        }
        Target      = $script:dscTargetName
    } # end data point
    VersionInformation     = @{
        Description = 'The PsVersionTable and OS version information'
        ScriptBlock = {
            param($tempPath)
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            $PSVersionTable | Out-String | Out-File   $tempPath\psVersionTable.txt
            Get-CimInstance win32_operatingSystem | select version | out-string | Out-File   $tempPath\osVersion.txt
        }
        Target      = $script:windowsTargetName
    } # end data point
    CertThumbprints        = @{
        Description = 'The local machine cert thumbprints.'
        ScriptBlock = {
            param($tempPath)
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            dir Cert:\LocalMachine\My\ | select -ExpandProperty Thumbprint | out-string | out-file $tempPath\LocalMachineCertThumbprints.txt
        }
        Target      = $script:windowsTargetName
    } # end data point
    DscResourceInventory   = @{
        Description = 'The name, version and path to installed dsc resources.'
        ScriptBlock = {
            param($tempPath)
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            Get-DscResource 2> $tempPath\ResourceErrors.txt | select name, version, path | out-string | out-file $tempPath\ResourceInfo.txt
        }
        Target      = $script:dscTargetName
    } # end data point
    DscConfigurationStatus = @{
        Description = 'The output of Get-DscConfigurationStatus -all'
        ScriptBlock = {
            param($tempPath)
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            $statusCommand = get-Command -name Get-DscConfigurationStatus -ErrorAction SilentlyContinue
            if ($statusCommand)
            {
                Get-DscConfigurationStatus -All | out-string | Out-File   $tempPath\get-dscconfigurationstatus.txt
            } }
        Target      = $script:dscTargetName
    } # end data point
}
