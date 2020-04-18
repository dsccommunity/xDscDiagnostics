
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
    Describe 'New-xDscDiagnosticsZip' {
        Context "invalid calls" {
            it "should throw" {
                { $dataPoints = Get-xDscDiagnosticsZip -includedDataPoint @('test', 'test2') } | should throw 'Cannot validate argument on parameter ''includedDataPoint''. IncluedDataPoint must be an array of xDscDiagnostics datapoint objects.'
            }

        }
        $testFolder = 'testdrive:\GetxDscDiagnosticsZip'
        md $testFolder > $null
        $Global:GetxDscDiagnosticsZipPath = (Resolve-Path $testFolder)

        Context 'verify with high level mock' {


            Mock Invoke-Command -MockWith { return $Global:GetxDscDiagnosticsZipPath }
            Mock Get-FolderAsZip -MockWith { Write-Verbose "executing Get-FolderAsZip mock" }
            Mock Collect-DataPoint -MockWith { return $true }
            Mock Start-Process -MockWith { Write-Verbose "executing start-process mock" }

            it 'should collect data and zip the data' {
                New-xDscDiagnosticsZip -confirm:$false
                Assert-MockCalled -CommandName Invoke-Command -Times 2
                Assert-MockCalled -CommandName Get-FolderAsZip -Times 1
                Assert-MockCalled -CommandName Start-Process -Times 1
                Assert-MockCalled -CommandName Collect-DataPoint -Times 10
            }
        }

        Context 'verify with high level mock with eventlog datapoints' {


            Mock Invoke-Command -MockWith { return $Global:GetxDscDiagnosticsZipPath }
            Mock Get-FolderAsZip -MockWith { Write-Verbose "executing Get-FolderAsZip mock" }
            Mock Collect-DataPoint -MockWith { return $true }
            Mock Start-Process -MockWith { Write-Verbose "executing start-process mock" }

            it 'should collect data and zip the data' {
                New-xDscDiagnosticsZip -confirm:$false -includedDataPoint (@(Get-xDscDiagnosticsZipDataPoint).where{ $_.name -like '*eventlog' })
                Assert-MockCalled -CommandName Invoke-Command -Times 2
                Assert-MockCalled -CommandName Get-FolderAsZip -Times 1
                Assert-MockCalled -CommandName Start-Process -Times 1
                Assert-MockCalled -CommandName Collect-DataPoint -Times 5
            }
        }

        context 'verify with lower level mocks' {
            $testPackageFolder = 'testdrive:\package'
            md $testPackageFolder > $null
            $Global:GetxDscDiagnosticsPackagePath = (Resolve-Path $testPackageFolder)
            Mock Get-ChildItem -MockWith {
                dir -LiteralPath $Global:GetxDscDiagnosticsPackagePath
            } -ParameterFilter { $Path -eq 'C:\Packages\Plugins\Microsoft.Powershell.*DSC' }
            Mock Get-ChildItem -MockWith {
                dir -LiteralPath $Global:GetxDscDiagnosticsZipPath
            } -ParameterFilter { $null -ne $path -and $Path -ne 'C:\Packages\Plugins\Microsoft.Powershell.*DSC' -and $path -notlike '*DscPackageFolder' }
            Mock Copy-Item -MockWith {
                '' | out-file $destination -ErrorAction SilentlyContinue
            } -ParameterFilter { $path -notmatch '\*.\*' }
            Mock Copy-Item -MockWith { } -ParameterFilter { $path -match '\*.\*' }
            Mock Test-Path -MockWith {
                $true
            } -ParameterFilter { $Path -eq "$env:windir\system32\configuration\DscEngineCache.mof" }
            mock Get-hotfix -MockWith { [PSCustomObject] @{mockedhotix = 'kb1' } }
            mock Get-DscLocalConfigurationManager -MockWith { [PSCustomObject] @{mockedmeta = 'meta1' } }
            mock Get-CimInstance -MockWith { [PSCustomObject] @{mockedwin32os = 'os1' } }
            mock Get-DSCResource -MockWith { [PSCustomObject] @{mockedresource = 'resource1' } }
            $statusCommand = get-Command -name Get-DscConfigurationStatus -ErrorAction SilentlyContinue
            if ($statusCommand)
            {
                mock Get-DscConfigurationStatus -MockWith { [PSCustomObject] @{mockedstatus = 'status1' } }
            }
            mock Get-Content -MockWith { [PSCustomObject] @{mockedEngineCache = 'engineCache1' } }

            Mock Get-FolderAsZip -MockWith { }
            Mock Start-Process -MockWith { }
            mock Export-EventLog -MockWith { }
            mock Test-PullServerPresent -MockWith { $true }
            Mock Collect-DataPoint -MockWith { return $true } -ParameterFilter { $Name -eq 'IISLogs' }


            it 'should collect data and zip the data' {
                New-xDscDiagnosticsZip -confirm:$false
                Assert-MockCalled -CommandName Get-FolderAsZip -Times 1 -Exactly
                Assert-MockCalled -CommandName Start-Process -Times 1 -Exactly
                Assert-MockCalled -CommandName Copy-item -Times 4 -Exactly
                Assert-MockCalled -CommandName Get-HotFix -Times 1 -Exactly
                Assert-MockCalled -CommandName Get-DscLocalConfigurationManager -Times 1 -Exactly
                Assert-MockCalled -CommandName Get-CimInstance -Times 1 -Exactly
                Assert-MockCalled -CommandName Get-DSCResource -Times 1 -Exactly
                Assert-MockCalled -CommandName Get-Content -Times -0 -Exactly
                Assert-MockCalled -CommandName Collect-DataPoint -Times 0 -Exactly
                if ($statusCommand)
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
}
