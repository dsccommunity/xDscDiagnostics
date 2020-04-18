
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
    Describe 'Get-FolderAsZip' {
        Context 'Without Session returning path' {
            <#
                [string]$sourceFolder,
                [string] $destinationPath,
                [System.Management.Automation.Runspaces.PSSession] $Session,
                [ValidateSet('Path','Content')]
                [string] $ReturnValue = 'Path',
                [string] $filename
            #>
            It 'Should zip a text file' {
                $testFolder = 'testdrive:\ziptest'
                md $testFolder > $null
                $resolvedTestDrive = (Resolve-Path $testDrive)
                $resolvedTestFolder = (Resolve-Path $testFolder).ProviderPath
                'test' | Out-File -FilePath (Join-path $resolvedTestFolder 'test.txt')

                # Issue, should take powershell paths.
                Get-FolderAsZip -sourceFolder $resolvedTestFolder -destinationPath (Join-path $resolvedTestDrive 'zipout') -filename test.zip

                Test-path testdrive:\zipout\test.zip | should be $true
            }


        }
        Context 'With Session returning content' {

        }
    }
}
