
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
    Describe "Get-xDscConfigurationDetail" {
        $testFile1 = 'TestDrive:\id-0.details.json'
        $testFile2 = 'TestDrive:\id-1.details.json'
        Mock Get-ChildItem -MockWith {
            @(
                [PSCustomObject] @{
                    FullName = $testFile1
                }
                [PSCustomObject]@{
                    FullName = $testFile2
                }
            )
        }
        $status = new-object -TypeName 'Microsoft.Management.Infrastructure.CimInstance' -argumentList @('MSFT_DSCConfigurationStatus')
        $status.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create('JobId', 'id', [Microsoft.Management.Infrastructure.CimFlags]::None))
        $status.CimInstanceProperties.Add([Microsoft.Management.Infrastructure.CimProperty]::Create('Type', 'type', [Microsoft.Management.Infrastructure.CimFlags]::None))
        <#$status = [PSCustomObject] @{
            CimClass=@{
                CimClassName='MSFT_DSCConfigurationStatus'
            }
            JobId='id'
            Type='type'
        }#>
        @(
            @{
                name = 'name1'
            }
            @{
                name = 'name2'
            }
        ) | convertto-json | out-file $testFile1
        @(
            @{
                name = 'name3'
            }
            @{
                name = 'name4'
            }
        ) | convertto-json | out-file $testFile2

        Context "returning records from multiple files" {

            $results = $status | Get-xDscConfigurationDetail -verbose
            it 'should return 4 records' {
                $results.Count | should be 4
            }
            it 'record 4 should be name4' {
                $results[3].name | should be 'name4'
                $results[0].name | should be 'name1'
            }

        }

        Context "invalid input" {
            Write-verbose "ccn: $($status.CimClass.CimClassName)" -Verbose
            $invalidStatus = [PSCustomObject] @{
                JobId = 'id'
                Type = 'type'
            }

            it 'should throw cannot process argument' {
                { Get-xDscConfigurationDetail -verbose -ConfigurationStatus $invalidStatus } | should throw 'Cannot validate argument on parameter 'ConfigurationStatus'. Must be a configuration status object".'
            }
        }
    }
}
