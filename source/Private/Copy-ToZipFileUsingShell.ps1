# Copy files using the Shell.
#
# Note, because this uses shell this will not work on core OSs
# But we only use this on older OSs and in test, so core OS use
# is unlikely
function Copy-ToZipFileUsingShell
{
    param
    (
        [string]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                if ($_ -notlike '*.zip')
                {
                    throw 'zipFileName must be *.zip'
                }
                else
                {
                    return $true
                }
            })]
        $zipfilename,

        [string]
        [ValidateScript( {
                if (-not (Test-Path $_))
                {
                    throw 'itemToAdd must exist'
                }
                else
                {
                    return $true
                }
            })]
        $itemToAdd,

        [switch]
        $overWrite
    )
    Set-StrictMode -Version latest
    if (-not (Test-Path $zipfilename) -or $overWrite)
    {
        set-content $zipfilename ('PK' + [char]5 + [char]6 + ("$([char]0)" * 18))
    }
    $app = New-Object -com shell.application
    $zipFile = ( Get-Item $zipfilename ).fullname
    $zipFolder = $app.namespace( $zipFile )
    $itemToAdd = (Resolve-Path $itemToAdd).ProviderPath
    $zipFolder.copyhere( $itemToAdd )
}
