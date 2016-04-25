<#
.Synopsis
   Unit tests for CollectDscDiagnostics.psm1
.DESCRIPTION


.NOTES
   Code in HEADER and FOOTER regions are standard and may be moved into DSCResource.Tools in
   Future and therefore should not be altered if possible.
#>


# TODO: Customize these parameters...
$Global:ModuleName      = 'CollectDscDiagnostics' # Example xNetworking
# /TODO

#region HEADER
[String] $moduleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $Script:MyInvocation.MyCommand.Path))
if ( (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'))
}
else
{
    & git @('-C',(Join-Path -Path $moduleRoot -ChildPath '\DSCResource.Tests\'),'pull')
}
Import-Module (Join-Path -Path $moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path $moduleRoot -ChildPath "$Global:ModuleName.psm1") -Force
#endregion

# TODO: Other Optional Init Code Goes Here...

# Begin Testing
try
{

    #region Pester Tests

    # The InModuleScope command allows you to perform white-box unit testing on the internal
    # (non-exported) code of a Script Module.
    InModuleScope $Global:ModuleName {

        #region Pester Test Initialization
        # TODO: Optional Load Mock for use in Pester tests here...
        #endregion


        #region Function Get-FolderAsZip
        Describe "$($Global:ModuleName)\Get-FolderAsZip" {
            Context -Name 'Without Session returning path' -Fixture {
                    <#[string]$sourceFolder,
        [string] $destinationPath,
        [System.Management.Automation.Runspaces.PSSession] $Session,
        [ValidateSet('Path','Content')]
        [string] $ReturnValue = 'Path',
        [string] $filename#>
                It 'Should zip a text file' {
                    $testFolder = 'testdrive:\ziptest'
                    md $testFolder > $null
                    $resolvedTestDrive = (Resolve-Path $testDrive)
                    $resolvedTestFolder  = (Resolve-Path $testFolder).ProviderPath
                    'test' | Out-File -FilePath (Join-path $resolvedTestFolder 'test.txt')
                    
                    # Issue, should take powershell paths.
                    Get-FolderAsZip -sourceFolder $resolvedTestFolder -destinationPath (Join-path $resolvedTestDrive 'zipout') -filename test.zip
                     
                    Test-path testdrive:\zipout\test.zip | should be $true                    
                }
                
            
            }
            Context -Name 'With Session returning content' -Fixture {
                
            }
        }
        #endregion


        #region Function Test-ContainerParameter
        Describe "$($Global:ModuleName)\Test-ContainerParameter" {
            $testFolder = 'testdrive:\testcontainerPath'
            md $testFolder > $null
            $testFile = (Join-path $testFolder 'test.txt')
            'test' | Out-File -FilePath $testFile
             
            it 'should throw when path is not container' {
                {Test-ContainerParameter -Path $testFile} | should throw 'Path parameter must be a valid container.'    
            }
            it 'should not throw when path is not container' {
                {Test-ContainerParameter -Path $testFolder} | should not throw 
            }
        }
        #endregion


        #region Function Export-EventLog
        Describe "$($Global:ModuleName)\Export-EventLog" {
            Context -Name 'Without Session' -Fixture {
                $testFolder = 'testdrive:\eventlogexporttest'
                md $testFolder > $null
                $resolvedTestDrive = (Resolve-Path $testDrive)
                $resolvedTestFolder  = (Resolve-Path $testFolder).ProviderPath
                it 'should generate a evtx file' {
                    Write-Verbose -Message "Path to export to: $resolvedTestFolder" -Verbose
                    Export-EventLog -Name Microsoft-Windows-DSC/Operational -Path $resolvedTestFolder
                    Test-path (Join-Path $testFolder Microsoft-Windows-DSC-Operational.evtx) | should be $true
                }
            }
            Context -Name 'With Session' -Fixture {
            }
        }
        #endregion

        #region Function Get-xDscDiagnosticsZip
        Describe "$($Global:ModuleName)\New-xDscDiagnosticsZip" {
            $testFolder = 'testdrive:\GetxDscDiagnosticsZip'
            md $testFolder > $null
            $Global:GetxDscDiagnosticsZipPath = (Resolve-Path $testFolder)
            
            Context 'verify with high level mock' {
                
            
                Mock Invoke-Command -MockWith { return $Global:GetxDscDiagnosticsZipPath}
                Mock Get-FolderAsZip -MockWith {}
                Mock Start-Process -MockWith {}
                
                it 'should collect data and zip the data' {
                    New-xDscDiagnosticsZip -confirm:$false
                    Assert-MockCalled -CommandName Invoke-Command -Times 2
                    Assert-MockCalled -CommandName Get-FolderAsZip -Times 1
                    Assert-MockCalled -CommandName Start-Process -Times 1
                }
            }
            context 'verify with lower level mocks' {
                $testPackageFolder = 'testdrive:\package'
                md $testPackageFolder > $null
                $Global:GetxDscDiagnosticsPackagePath = (Resolve-Path $testPackageFolder)
                Mock Get-ChildItem -MockWith {
                        dir -LiteralPath $Global:GetxDscDiagnosticsPackagePath
                    } -ParameterFilter {$Path -eq 'C:\Packages\Plugins\Microsoft.Powershell.*DSC'}
                Mock Get-ChildItem -MockWith {
                        dir -LiteralPath $Global:GetxDscDiagnosticsZipPath
                    } -ParameterFilter {$null -ne $path -and $Path -ne 'C:\Packages\Plugins\Microsoft.Powershell.*DSC' -and $path -notlike '*DscPackageFolder'}
                Mock Copy-Item -MockWith { 
                        '' | out-file $destination -ErrorAction SilentlyContinue
                    } -ParameterFilter {$path -notmatch '\*.\*'}
                Mock Copy-Item -MockWith {} -ParameterFilter {$path -match '\*.\*'}
                mock Get-hotfix -MockWith {[PSCustomObject]@{mockedhotix='kb1'}}
                mock Get-DscLocalConfigurationManager -MockWith {[PSCustomObject]@{mockedmeta='meta1'}}
                mock Get-CimInstance -MockWith {[PSCustomObject]@{mockedwin32os='os1'}}
                mock Get-DSCResource -MockWith {[PSCustomObject]@{mockedresource='resource1'}}
                $statusCommand = get-Command -name Get-DscConfigurationStatus -ErrorAction SilentlyContinue
                if($statusCommand)
                { 
                    mock Get-DscConfigurationStatus -MockWith {[PSCustomObject]@{mockedstatus='status1'}}
                }
                mock Get-Content -MockWith {[PSCustomObject]@{mockedEngineCache='engineCache1'}}
                
                Mock Get-FolderAsZip -MockWith {}
                Mock Start-Process -MockWith {}
                mock Export-EventLog -MockWith {}
                
                it 'should collect data and zip the data' {
                    New-xDscDiagnosticsZip -confirm:$false
                    Assert-MockCalled -CommandName Get-FolderAsZip -Times 1 -Exactly
                    Assert-MockCalled -CommandName Start-Process -Times 1 -Exactly
                    Assert-MockCalled -CommandName Copy-item -Times 4 -Exactly
                    Assert-MockCalled -CommandName Get-HotFix -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-DscLocalConfigurationManager -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-CimInstance -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-DSCResource -Times 1 -Exactly
                    Assert-MockCalled -CommandName Get-Content -Times 1 -Exactly
                    if($statusCommand)
                    { 
                        Assert-MockCalled -CommandName Get-DscConfigurationStatus -Times 1 -Exactly
                    }
                    Assert-MockCalled -CommandName Export-EventLog -Times 3 -Exactly
                }
            }
            context 'verify alias' {
                it 'should be aliased' {
                    (get-alias -Name Get-xDscDiagnosticsZip).ResolvedCommand.Name | should be 'New-xDscDiagnosticsZip'
                }
            }
        }
        #endregion
        
        Describe "$($Global:ModuleName)\Get-XDscConfigurationDetail" {
            $testFile1='TestDrive:\id-0.details.json'
            $testFile2='TestDrive:\id-1.details.json'
            Mock Get-ChildItem -MockWith {@([PSCustomObject]@{
                FullName = $testFile1
            }
            [PSCustomObject]@{
                FullName = $testFile2
            }
            )}
            $status = new-object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -argumentList @('MSFT_DSCConfigurationStatus')                                                                                                        
            $status.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create('JobId','id', [Microsoft.Management.Infrastructure.CimFlags]::None))  
            $status.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create('Type','type', [Microsoft.Management.Infrastructure.CimFlags]::None))  
            <#$status = [PSCustomObject] @{
                CimClass=@{
                    CimClassName='MSFT_DSCConfigurationStatus'
                }
                JobId='id'
                Type='type'
            }#>
            @(@{
                name='name1'
            }
            @{
                name='name2'
            }
            ) | convertto-json | out-file $testFile1
            @(@{
                name='name3'
            }
            @{
                name='name4'
            }
            ) | convertto-json | out-file $testFile2
            context "returning records from multiple files" {
                
                $results = $status | Get-XDscConfigurationDetail -verbose
                it 'should return 4 records' {
                    $results.Count | should be 4
                }
                it 'record 4 should be name4' {
                    $results[3].name | should be 'name4'
                    $results[0].name | should be 'name1'
                }
                
            }
            context "invalid input" {
                Write-verbose "ccn: $($status.CimClass.CimClassName)" -Verbose
                $invalidStatus = [PSCustomObject] @{JobId = 'id'; Type = 'type'}
                
                it 'should throw cannot process argument' {
                    {Get-XDscConfigurationDetail -verbose -ConfigurationStatus $invalidStatus}| should throw 'Cannot process argument transformation on parameter 'ConfigurationStatus'. Cannot convert the "@{JobId=id; Type=type}" value of type "System.Management.Automation.PSCustomObject" to type "Microsoft.Management.Infrastructure.CimInstance".'
                }
            }
        }


        # TODO: Pester Tests for any Helper Cmdlets

    }
    #endregion
}
finally
{
    #region FOOTER
    #endregion

    # TODO: Other Optional Cleanup Code Goes Here...
}
