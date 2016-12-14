$width = 900
#
# Zips the specified folder  
# returns either the path or the contents of the zip files based on the returnvalue parameterer
# When using the contents, Use set-content to create a zip file from it.
# on the specified session, if the session is not specified
# a session to the local machine will be used
# 
#
function Get-FolderAsZip
{
    [CmdletBinding()]
    param(

        [string]$sourceFolder,
        [string] $destinationPath,
        [System.Management.Automation.Runspaces.PSSession] $Session,
        [ValidateSet('Path','Content')]
        [string] $ReturnValue = 'Path',
        [string] $filename
    )

    $local = $false
    $invokeCommandParams = @{}
    if($Session)
    {
        $invokeCommandParams.Add('Session',$Session);
    }
    else
    {
        $local = $true
    }

    $attempts =0 
    $gotZip = $false
    while($attempts -lt 5 -and !$gotZip)
    {
        $attempts++
        $resultTable = invoke-command -ErrorAction:Continue @invokeCommandParams -script {
                param($logFolder, $destinationPath, $fileName, $ReturnValue)
                $ErrorActionPreference = 'stop'
                Set-StrictMode -Version latest


                $tempPath = Join-path $env:temp ([system.io.path]::GetRandomFileName())
                if(!(Test-Path $tempPath))
                {
                    mkdir $tempPath > $null
                }
                
                $sourcePath = Join-path $logFolder '*'
                Copy-Item -Recurse $sourcePath $tempPath -ErrorAction SilentlyContinue

                $content = $null
                $caughtError = $null
                try 
                {
                    # Copy files using the Shell.  
                    # 
                    # Note, because this uses shell this will not work on core OSs
                    # But we only use this on older OSs and in test, so core OS use
                    # is unlikely
                    function Copy-ToZipFileUsingShell
                    {
                        param (
                            [string]
                            [ValidateNotNullOrEmpty()]
                            [ValidateScript({ if($_ -notlike '*.zip'){ throw 'zipFileName must be *.zip'} else {return $true}})]
                            $zipfilename,

                            [string]
                            [ValidateScript({ if(-not (Test-Path $_)){ throw 'itemToAdd must exist'} else {return $true}})]
                            $itemToAdd,

                            [switch]
                            $overWrite
                        )
                        Set-StrictMode -Version latest
                        if(-not (Test-Path $zipfilename) -or $overWrite)
                        {
                            set-content $zipfilename ('PK' + [char]5 + [char]6 + ("$([char]0)" * 18))
                        }
                        $app = New-Object -com shell.application
                        $zipFile = ( Get-Item $zipfilename ).fullname
                        $zipFolder = $app.namespace( $zipFile )
                        $itemToAdd = (Resolve-Path $itemToAdd).ProviderPath
                        $zipFolder.copyhere( $itemToAdd )
                    }
                    
                    # Generate an automatic filename if filename is not supplied
                    if(!$fileName)
                    {
                        $fileName = "$([System.IO.Path]::GetFileName($logFolder))-$((Get-Date).ToString('yyyyMMddhhmmss')).zip"
                    }
                    
                    if($destinationPath)
                    {
                        $zipFile = Join-Path $destinationPath $fileName

                        if(!(Test-Path $destinationPath))
                        {
                            mkdir $destinationPath > $null
                        }
                    }
                    else
                    {
                        $zipFile = Join-Path ([IO.Path]::GetTempPath()) ('{0}.zip' -f $fileName)
                    }
                    
                    # Choose appropriate implementation based on CLR version
                    if ($PSVersionTable.CLRVersion.Major -lt 4)
                    {
                        Copy-ToZipFileUsingShell -zipfilename $zipFile -itemToAdd $tempPath 
                        $content = Get-Content $zipFile | Out-String
                    }
                    else
                    {
                        Add-Type -AssemblyName System.IO.Compression.FileSystem > $null
                        [IO.Compression.ZipFile]::CreateFromDirectory($tempPath, $zipFile) > $null
                        $content = Get-Content -Raw $zipFile
                    }
                }
                catch [Exception]
                {
                    $caughtError = $_
                }
                
                if($ReturnValue -eq 'Path')
                {
                    # Don't return content if we don't need it
                    return @{
                            Content = $null
                            Error = $caughtError
                            zipFilePath = $zipFile
                        }
                }
                else
                {
                    return @{
                            Content = $content
                            Error = $caughtError
                            zipFilePath = $zipFile
                        }                
                }             
            } -argumentlist @($sourceFolder,$destinationPath, $fileName, $ReturnValue) -ErrorVariable zipInvokeError 
            

            if($zipInvokeError -or $resultTable.Error)
            {
                if($attempts -lt 5)
                {
                    Write-Debug "An error occured trying to zip $sourceFolder .  Will retry..."
                    Start-Sleep -Seconds $attempts
                }
                else {
                    if($resultTable.Error)
                    {
                        $lastError = $resultTable.Error
                    }
                    else 
                    {
                        $lastError = $zipInvokeError[0]    
                    }
                    
                    Write-Warning "An error occured trying to zip $sourceFolder .  Aborting."
                    Write-ErrorInfo -ErrorObject $lastError -WriteWarning

                }
            }
            else
            {
                $gotZip = $true
            }
    }
    
    if($ReturnValue -eq 'Path')
    {
        $result = $resultTable.zipFilePath
    }
    else 
    {
        $result = $resultTable.content
    }

    return $result
}

#
# Tests if a parameter is a container, to be used in a ValidateScript attribute
#
function Test-ContainerParameter
{
  [CmdletBinding()]
  param(
    [string] $Path,
    [string] $Name = 'Path'
  )

  if(!(Test-Path $Path -PathType Container))
  {
    throw "$Name parameter must be a valid container."
  }

  return $true
}

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
    $invokeCommandParams = @{}
    if($Session)
    {
        $invokeCommandParams.Add('Session',$Session);
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

#
# Checks if this machine is a Server SKU
#
function Test-ServerSku
{
    [CmdletBinding()]
    $os = Get-CimInstance -ClassName  Win32_OperatingSystem
    $isServerSku = ($os.ProductType -ne 1)
}

#
# Verifies if Pull Server is installed on this machine
#
function Test-PullServerPresent
{
    [CmdletBinding()]
    
    $isPullServerPresent = $false;   

    $isServerSku = Test-ServerSku

    if ($isServerSku)
    {
        Write-Verbose "This is a Server machine"
        $website = Get-WebSite PSDSCPullServer -erroraction silentlycontinue
        if ($website -ne $null)
        {
            $isPullServerPresent = $true
        }        
    }    

    Write-Verbose "This is not a pull server"
    return $isPullServerPresent
}


$AzureDscExtensionTargetName = 'Azure DSC Extension'
$DscTargetName = 'DSC Node'
$WindowsTargetName = 'Windows'
$DscPullServerTargetName = 'DSC Pull Server'
$validTargets = @($AzureDscExtensionTargetName,$DscTargetName,$WindowsTargetName,$DscPullServerTargetName)
$defaultTargets = @($AzureDscExtensionTargetName,$DscTargetName,$WindowsTargetName)
$dataPoints = @{
    AzureVmAgentLogs = @{
        Description = 'Logs from the Azure VM Agent, including all extensions'
        Target = $AzureDscExtensionTargetName
        ScriptBlock = {
            param($tempPath)    
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            Copy-Item -Recurse C:\WindowsAzure\Logs $tempPath\WindowsAzureLogs -ErrorAction SilentlyContinue
        }
    } # end data point
    DSCExtension = @{
        Description = @'
The state of the Azure DSC Extension, including the configuration(s), 
configuration data (but not any decryption keys), and included or 
generated files.
'@
        Target = $AzureDscExtensionTargetName
        ScriptBlock = {
            param($tempPath)
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            $dirs = @(Get-ChildItem -Path C:\Packages\Plugins\Microsoft.Powershell.*DSC -ErrorAction SilentlyContinue) 
            $dir = $null
            if($dirs.Count -ge 1)
            {
                $dir = $dirs[0].FullName
            }

            if($dir)
            {
                Write-Verbose -message "Found DSC extension at: $dir" -verbose
                Copy-Item -Recurse $dir $tempPath\DscPackageFolder -ErrorAction SilentlyContinue 
                Get-ChildItem "$tempPath\DscPackageFolder" -Recurse | %{
                        if($_.Extension -ieq '.msu' -or ($_.Extension -ieq '.zip' -and $_.BaseName -like 'Microsoft.Powershell*DSC_*.*.*.*'))
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
    DscEventLog = @{
        Description = 'The DSC event log.'
        EventLog = 'Microsoft-Windows-DSC/Operational'
        Target = $DscTargetName
    } # end data point
    ApplicationEventLog = @{
        Description = 'The Application event log.'
        EventLog = 'Application'
        Target = $WindowsTargetName
    } # end data point
    SystemEventLog = @{
        Description = 'The System event log.'
        EventLog = 'System'
        Target = $WindowsTargetName
    } # end data point
    PullServerEventLog = @{
        Description = 'The DSC Pull Server event log.'
        EventLog = 'Microsoft-Windows-PowerShell-DesiredStateConfiguration-PullServer/Operational'
        Target = $DscPullServerTargetName
    } # end data point
    ODataEventLog = @{
        Description = 'The Management OData event log (used by the DSC Pull Server).'
        EventLog = 'Microsoft-Windows-ManagementOdataService/Operational'
        Target = $DscPullServerTargetName
    } # end data point
    IisBinding = @{
        Description = 'The Iis Bindings.'
        ScriptBlock = {
            param($tempPath)    
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            Get-WebBinding | Select-Object protocol, bindingInformation, sslFlags, ItemXPath | 
                Out-String -Width $width | Out-File -FilePath $tempPath\IisBindings.txt -Width $width
        }
        Target = $DscPullServerTargetName
    } # end data point
    HttpErrLogs = @{
        Description = 'The HTTPERR logs.'
        ScriptBlock = {
            param($tempPath)    
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            mkdir $tempPath\HttpErr > $null
            Copy-Item $env:windir\System32\LogFiles\HttpErr\*.* $tempPath\HttpErr -ErrorAction SilentlyContinue
        }
        Target = $DscPullServerTargetName
    } # end data point
    IISLogs = @{
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
        Target = $DscPullServerTargetName
    } # end data point
    ServicingLogs = @{
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
        Target = $WindowsTargetName
    } # end data point
    HotfixList = @{
        Description = 'The output of Get-Hotfix'
        ScriptBlock = {
            param($tempPath)    
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            Get-HotFix | Out-String | Out-File  $tempPath\HotFixIds.txt
        }
        Target = $WindowsTargetName
    } # end data point
    GetLcmOutput = @{
        Description = 'The output of Get-DscLocalConfigurationManager'
        ScriptBlock = {
            param($tempPath)    
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            $dscLcm = Get-DscLocalConfigurationManager
            $dscLcm | Out-String | Out-File   $tempPath\Get-dsclcm.txt
            $dscLcm | ConvertTo-Json -Depth 10 | Out-File   $tempPath\Get-dsclcm.json
        }
        Target = $DscTargetName
    } # end data point
    VersionInformation = @{
        Description = 'The PsVersionTable and OS version information'
        ScriptBlock = {
            param($tempPath)    
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            $PSVersionTable | Out-String | Out-File   $tempPath\psVersionTable.txt
            Get-CimInstance win32_operatingSystem | select version | out-string  | Out-File   $tempPath\osVersion.txt
        }
        Target = $WindowsTargetName
    } # end data point
    CertThumbprints = @{
        Description = 'The local machine cert thumbprints.'
        ScriptBlock = {
            param($tempPath)    
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            dir Cert:\LocalMachine\My\ |select -ExpandProperty Thumbprint | out-string | out-file $tempPath\LocalMachineCertThumbprints.txt
        }
        Target = $WindowsTargetName
    } # end data point
    DscResourceInventory = @{
        Description = 'The name, version and path to installed dsc resources.'
        ScriptBlock = {
            param($tempPath)    
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            Get-DscResource 2> $tempPath\ResourceErrors.txt | select name, version, path | out-string | out-file $tempPath\ResourceInfo.txt 
        }
        Target = $DscTargetName
    } # end data point
    DscConfigurationStatus = @{
        Description = 'The output of Get-DscConfigurationStatus -all'
        ScriptBlock = {
            param($tempPath)    
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest
            $statusCommand = get-Command -name Get-DscConfigurationStatus -ErrorAction SilentlyContinue
            if($statusCommand)
            { 
                Get-DscConfigurationStatus -All | out-string  | Out-File   $tempPath\get-dscconfigurationstatus.txt
            }        }
        Target = $DscTargetName
    } # end data point
}

$datapointTypeName = 'xDscDiagnostics.DataPoint'
# Returns a list of datapoints which will be collected by
# New-xDscDiagnosticsZip 
function Get-xDscDiagnosticsZipDataPoint
{
    foreach($key in $dataPoints.Keys)
    {
        $dataPoint = $dataPoints.$key
        $dataPointObj = ([PSCustomObject] @{
            Name = $key
            Description = $dataPoint.Description
            Target = $dataPoint.Target
        })
        $dataPointObj.pstypenames.Clear()
        $dataPointObj.pstypenames.Add($datapointTypeName)
        Write-Output $dataPointObj
    }
}

# attempts to Collect a datapoint 
# Returns $true if it believes it collected the datapoint
function Collect-DataPoint
{
    param (
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
    if($dataPoint.ScriptBlock)
    {
        Write-Verbose -Message "Collecting '$name-$($dataPoint.Description)' using ScripBlock ..."
        Invoke-Command -ErrorAction:Continue @invokeCommandParams -script $dataPoint.ScriptBlock -argumentlist @($tempPath)
        $collected = $true
    }

    if($dataPoint.EventLog)
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

#
# Gathers diagnostics for DSC and the DSC Extension into a zipfile 
# if specified, in the specified path
# if specified, in the specified filename
# on the specified session, if the session is not specified
# a session to the local machine will be used
#
function New-xDscDiagnosticsZip
{
    [CmdletBinding(    SupportsShouldProcess=$true,        ConfirmImpact='High', DefaultParameterSetName='default'    )]
    param(
        [Parameter(ParameterSetName='default')]        
        [Parameter(ParameterSetName='includedDataPoints')]
        [Parameter(ParameterSetName='includedTargets')]
        [System.Management.Automation.Runspaces.PSSession] $Session,

        [Parameter(ParameterSetName='default')]
        [Parameter(ParameterSetName='includedDataPoints')]
        [Parameter(ParameterSetName='includedTargets')]
        [string] $destinationPath,

        [Parameter(ParameterSetName='default')]
        [Parameter(ParameterSetName='includedDataPoints')]
        [Parameter(ParameterSetName='includedTargets')]
        [string] $filename,

        [Parameter(ParameterSetName='includedDataPoints', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ foreach($point in $_) { if($_.pstypenames -notcontains $datapointTypeName){ throw 'IncluedDataPoint must be an array of xDscDiagnostics datapoint objects.'}} ; return $true })]
        [object[]] $includedDataPoint
    )
    DynamicParam {
        $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()

        $dataPointTargetsParametereAttribute = [System.Management.Automation.ParameterAttribute]::new()
        $dataPointTargetsParametereAttribute.Mandatory = $true
        $dataPointTargetsParametereAttribute.ParameterSetName = 'includedTargets'
        $attributeCollection.Add($dataPointTargetsParametereAttribute)

        $validateSetAttribute = [System.Management.Automation.ValidateSetAttribute]::new([string[]]$validTargets)

        $attributeCollection.Add($validateSetAttribute)
        $dataPointTargetsParam = New-Object System.Management.Automation.RuntimeDefinedParameter('DataPointTarget', [String[]], $attributeCollection)

        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        $paramDictionary.Add('DataPointTarget', $dataPointTargetsParam)
        return $paramDictionary
    }

    Process {
        [string[]] $dataPointTarget = $PSBoundParameters.DataPointTarget
        $dataPointsToCollect = @{}
        switch($pscmdlet.ParameterSetName)
        {
            "includedDataPoints" {
                foreach($dataPoint in $includedDataPoint)
                {
                    $dataPointsToCollect.Add($dataPoint.Name, $dataPoints.($dataPoint.Name))
                }                
            }
            "includedTargets" {
                foreach($key in $dataPoints.keys)
                {
                    $dataPoint = $dataPoints.$key
                    if($dataPointTarget -icontains $dataPoint.Target)
                    {
                        $dataPointsToCollect.Add($key, $dataPoint)
                    }
                }                
            }
            default {
                foreach($key in $dataPoints.keys)
                {
                    $dataPoint = $dataPoints.$key
                    if($defaultTargets -icontains $dataPoint.Target)
                    {
                        $dataPointsToCollect.Add($key, $dataPoint)
                    }
                }                
            }
        }

        $local = $false
        $invokeCommandParams = @{}
        if($Session)
        {
            $invokeCommandParams.Add('Session',$Session);
        }
        else
        {
            $local = $true
        }
        
        Function Write-ProgressMessage
        {
            [CmdletBinding()]
            param([string]$Status, [int]$PercentComplete, [switch]$Completed)

            Write-Progress -Activity 'Get-AzureVmDscDiagnostics' @PSBoundParameters
            Write-Verbose -message $status 
        }


    $privacyConfirmation = "Collecting the following information, which may contain private/sensative details including:"
        foreach($key in $dataPointsToCollect.Keys)
        {
            $dataPoint = $dataPointsToCollect.$key
            $privacyConfirmation += [System.Environment]::NewLine
            $privacyConfirmation += ("`t{0}" -f $dataPoint.Description)
        }
        $privacyConfirmation += [System.Environment]::NewLine
        $privacyConfirmation += "This tool is provided for your convience, to ensure all data is collected as quickly as possible."  
        $privacyConfirmation += [System.Environment]::NewLine
        $privacyConfirmation += "Are you sure you want to continue?"

        if ($pscmdlet.ShouldProcess($privacyConfirmation)) 
        {
            
            $tempPath = invoke-command -ErrorAction:Continue @invokeCommandParams -script {
                    $ErrorActionPreference = 'stop'
                    Set-StrictMode -Version latest
                    $tempPath = Join-path $env:temp ([system.io.path]::GetRandomFileName())
                    if(!(Test-Path $tempPath))
                    {
                        mkdir $tempPath > $null
                    }
                    return $tempPath
                }
            Write-Verbose -message "tempPath: $tempPath"

            $collectedPoints = 0
            foreach($key in $dataPointsToCollect.Keys)
            {
                $dataPoint = $dataPointsToCollect.$key
                if(!$dataPoint.Skip -or !(&$dataPoint.skip))
                {
                    Write-ProgressMessage  -Status "Collecting '$($dataPoint.Description)' ..." -PercentComplete ($collectedPoints/$dataPoints.Count)
                    $collected = Collect-DataPoint -dataPoint $dataPoint -invokeCommandParams $invokeCommandParams -Name $key
                    if(!$collected)
                    {
                        Write-Warning "Did not collect  '$($dataPoint.Description)'"
                    }
                }
                else {
                    Write-Verbose -Message "Skipping collecting '$($dataPoint.Description)' ..."
                }
                $collectedPoints ++
            }
            
            if(!$destinationPath)
            {
                Write-ProgressMessage  -Status 'Getting destinationPath ...' -PercentComplete 74
                $destinationPath = invoke-command -ErrorAction:Continue @invokeCommandParams -script { 
                    $ErrorActionPreference = 'stop'
                    Set-StrictMode -Version latest
                    Join-path $env:temp ([system.io.path]::GetRandomFileName()) 
                }
            }

            Write-Debug -message "destinationPath: $destinationPath" -verbose
            $zipParams = @{ 
                    sourceFolder = $tempPath
                    destinationPath = $destinationPath
                    Session = $session
                    fileName = $fileName
                }

            Write-ProgressMessage  -Status 'Zipping files ...' -PercentComplete 75
            if($local)
            {
                $zip = Get-FolderAsZip @zipParams
                $zipPath = $zip
            }
            else 
            {
                $zip = Get-FolderAsZip @zipParams -ReturnValue 'Content'   
                if(!(Test-Path $destinationPath))
                {
                    mkdir $destinationPath > $null
                }
                $zipPath = (Join-path $destinationPath "$($session.ComputerName)-dsc-diags-$((Get-Date).ToString('yyyyMMddhhmmss')).zip")
                set-content -path $zipPath -value $zip
            }

            Start-Process $destinationPath
            Write-Verbose -message "Please send this zip file the engineer you have been working with.  The engineer should have emailed you instructions on how to do this: $zipPath" -verbose
            Write-ProgressMessage  -Completed
            return $zipPath
        }

    }
}
New-Alias -Name Get-xDscDiagnosticsZip -Value New-xDscDiagnosticsZip

# Gets the Json details for a configuration status
function Get-XDscConfigurationDetail
{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true,ValuefromPipeline=$true,ParameterSetName="ByValue")]
    [ValidateScript({
      if($_.CimClass.CimClassName -eq 'MSFT_DSCConfigurationStatus') 
      {
        return $true
      }
      else
      {
        throw 'Must be a configuration status object'
      }
    })]
    $ConfigurationStatus,

    [Parameter(Mandatory=$true,ParameterSetName="ByJobId")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({
        [System.Guid] $jobGuid = [System.Guid]::Empty
        if([System.Guid]::TryParse($_, ([ref] $jobGuid))) 
        {
          return $true
        }
        else
        {
          throw 'JobId must be a valid GUID'
        }
    })]
    [string] $JobId
  )
  Process
  {
     [bool] $hasJobId = $false
     [string] $id = ''
     if ($null -ne $ConfigurationStatus)
     {
         $id = $ConfigurationStatus.JobId
     }
     else 
     {
        [System.Guid] $jobGuid = [System.Guid]::Parse($JobId)
        # ensure the job id string has the expected leading and trailing '{', '}' characters.       
        $id = $jobGuid.ToString('B')
     }

    $detailsFiles = Get-ChildItem -Path "$env:windir\System32\Configuration\ConfigurationStatus\$id-?.details.json"
    if($detailsFiles)
    {
      foreach($detailsFile in $detailsFiles)
      {
          Write-Verbose -Message "Getting details from: $($detailsFile.FullName)"
          (Get-Content -Encoding Unicode -raw $detailsFile.FullName) | ConvertFrom-Json | foreach-object { write-output $_}
      }
    }
    elseif ($null -ne $ConfigurationStatus)
    {
      if($($ConfigurationStatus.type) -eq 'Consistency')
      {
        Write-Warning -Message "DSC does not produced details for job type: $($ConfigurationStatus.type); id: $($ConfigurationStatus.JobId)"
      }
      else
      {
        Write-Error -Message "Cannot find detail for job type: $($ConfigurationStatus.type); id: $($ConfigurationStatus.JobId)"
      }      
    }
    else
    {
      throw "Cannot find configuration details for job $id"
    }
  }
}

# decrypt one of the lcm mof
function Unprotect-xDscConfiguration
{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true,ValuefromPipeline=$true)]
    [ValidateSet('Current','Pending','Previous')]
    $Stage
  )
    
    Add-Type -AssemblyName System.Security
    
    $path =  "$env:windir\System32\Configuration\$stage.mof"
    
    if(Test-Path $path)
    {

        $secureString = Get-Content $path -Raw 

        $enc = [system.Text.Encoding]::Default 

        $data = $enc.GetBytes($secureString)  

        $bytes = [System.Security.Cryptography.ProtectedData]::Unprotect( $data, $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine ) 

        $enc = [system.text.encoding]::Unicode 

        $enc.GetString($bytes)
    }
    else {
        throw (New-Object -TypeName 'System.IO.FileNotFoundException' -ArgumentList @("The stage $stage was not found"))
    } 
}

Export-ModuleMember -Function @(
    'New-xDscDiagnosticsZip'
    'Get-XDscConfigurationDetail'
    'Unprotect-xDscConfiguration'
    'Get-xDscDiagnosticsZipDataPoint'
) -Alias 'Get-xDscDiagnosticsZip'
