
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
    Describe 'Get-xDscDiagnosticsZipDataPoint' {
        It "should not throw" {
            { $dataPoints = Get-xDscDiagnosticsZipDataPoint } | should not throw
        }

        $dataPoints = @(Get-xDscDiagnosticsZipDataPoint)

        It "should return 17 points" {
            $dataPoints.Count | should be 17
        }

        foreach ($dataPoint in $dataPoints)
        {
            Context "DataPoint $($dataPoint.Name)" {
                It "should have name" {
                    $dataPoint.Name | should not benullorempty
                }

                It "should have description " {
                    $dataPoint.Description | should not benullorempty
                }

                It "should have a target" {
                    $dataPoint.Target | should not benullorempty
                }

                It "should be of type 'xDscDiagnostics.DataPoint'" {
                    $dataPoint.pstypenames[0] | should be 'xDscDiagnostics.DataPoint'
                }

                It "should have 2 NoteProperties" {
                    @($dataPoint | get-member -MemberType NoteProperty).count | should be 3
                }

                It "should have 4 Methods" {
                    # Methods, Equals, GetHashCode, GetType, ToString
                    @($dataPoint | get-member -MemberType Method).count | should be 4
                }

                It "should have no other members" {
                    @($dataPoint | get-member).count | should be 7
                }
            }
        }
    }
}
