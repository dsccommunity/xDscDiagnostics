
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
    Describe 'Test-ContainerParameter' {
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
}
