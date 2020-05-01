
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
    Describe 'Get-xDscConfigurationDetailByJobId' {
        $jobId = [System.Guid]::NewGuid().ToString('B')
        $testFile = "TestDrive:\$jobId-0.details.json"

        $status = new-object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -argumentList @('MSFT_DSCConfigurationStatus')
        $status.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create('JobId', 'id', [Microsoft.Management.Infrastructure.CimFlags]::None))
        $status.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create('Type', 'type', [Microsoft.Management.Infrastructure.CimFlags]::None))

        @(
            @{
                name = 'name1'
            }
            @{
                name = 'name2'
            }
        ) | convertto-json | out-file $testFile

        Context 'Get configuration details by job id' {
            # Path queried by Get-xDscConfigurationDetail to retrieve the configuration details file
            $gciParameter = "$env:windir\System32\Configuration\ConfigurationStatus\$jobId-?.details.json"

            Mock Get-ChildItem -MockWith {
                @(
                    [PSCustomObject] @{
                        FullName = $testFile
                    }
                )
            } -ParameterFilter {
                $Path -eq $gciParameter
            }

            $results = Get-xDscConfigurationDetail -jobId $jobId
            $results
            It 'should return 2 records' {
                $results.Count | should be 2
            }
            It 'record 0 should be name1' {
                $results[0].name | should be 'name1'
            }
            It 'record 1 should be name2' {
                $results[1].name | should be 'name2'
            }
        }

        Context 'Get configuration details using an invalid GUID for a job id' {
            It 'should throw cannot validate argument on parameter JobId' {
                { Get-xDscConfigurationDetail -JobId 'foo' } | should throw "Cannot validate argument on parameter 'JobId'. JobId must be a valid GUID"
            }
        }

        Context 'Get configuration details using a job id that does not exist' {
            $jobId = [System.Guid]::NewGuid().ToString('B')
            It 'should throw Cannot find configuration details for job' {
                { Get-xDscConfigurationDetail -JobId $jobId } | should throw "Cannot find configuration details for job $jobId"
            }
        }
    }
}
