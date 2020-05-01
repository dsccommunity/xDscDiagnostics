#region HEADER
$script:projectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            })
    }).BaseName

$script:moduleName = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

Import-Module $script:moduleName -Force -ErrorAction 'Stop'
#endregion HEADER

InModuleScope $script:moduleName {
    Describe 'Export-EventLog' {
        Context -Name 'Without Session' -Fixture {
            $testFolder = 'testdrive:\eventlogexporttest'
            md $testFolder > $null
            $resolvedTestDrive = (Resolve-Path $testDrive)
            $resolvedTestFolder = (Resolve-Path $testFolder).ProviderPath
            it 'should generate a evtx file' {
                Write-Verbose -Message "Path to export to: $resolvedTestFolder" -Verbose
                Export-EventLog -Name Microsoft-Windows-DSC/Operational -Path $resolvedTestFolder
                Test-path (Join-Path $testFolder Microsoft-Windows-DSC-Operational.evtx) | should be $true
            }
        }
        Context -Name 'With Session' -Fixture {
        }
    }
}
