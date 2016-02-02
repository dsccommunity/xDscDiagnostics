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
        # TODO: Optopnal Load Mock for use in Pester tests here...
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
        Describe "$($Global:ModuleName)\Get-xDscDiagnosticsZip" {
            $testFolder = 'testdrive:\GetxDscDiagnosticsZip'
            md $testFolder > $null
            $Global:GetxDscDiagnosticsZipPath = (Resolve-Path $testFolder)
            
            Mock Invoke-Command -MockWith { return $Global:GetxDscDiagnosticsZipPath}
            Mock Get-FolderAsZip -MockWith {}
            
            it 'should collect data and zip the data' {
                Get-xDscDiagnosticsZip -confirm:$false
                Assert-MockCalled -CommandName Invoke-Command -Times 2
                Assert-MockCalled -CommandName Get-FolderAsZip -Times 1
            }
        }
        #endregion


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
