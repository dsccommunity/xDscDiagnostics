#
# Zips the specified folder
# returns either the path or the contents of the zip files based on the returnvalue parameterer
# When using the contents, Use set-content to create a zip file from it.
# on the specified session, if the session is not specified
# a session to the local machine will be used
#
#
function Get-FolderAsZip
{
    [CmdletBinding()]
    param
    (
        [string]$sourceFolder,
        [string] $destinationPath,
        [System.Management.Automation.Runspaces.PSSession] $Session,
        [ValidateSet('Path', 'Content')]
        [string] $ReturnValue = 'Path',
        [string] $filename
    )

    $local = $false
    $invokeCommandParams = @{ }
    if ($Session)
    {
        $invokeCommandParams.Add('Session', $Session);
    }
    else
    {
        $local = $true
    }

    $attempts = 0
    $gotZip = $false
    while ($attempts -lt 5 -and !$gotZip)
    {
        $attempts++
        $resultTable = invoke-command -ErrorAction:Continue @invokeCommandParams -script {
            param ($logFolder, $destinationPath, $fileName, $ReturnValue)
            $ErrorActionPreference = 'stop'
            Set-StrictMode -Version latest


            $tempPath = Join-path $env:temp ([system.io.path]::GetRandomFileName())
            if (!(Test-Path $tempPath))
            {
                mkdir $tempPath > $null
            }

            $sourcePath = Join-path $logFolder '*'
            Copy-Item -Recurse $sourcePath $tempPath -ErrorAction SilentlyContinue

            $content = $null
            $caughtError = $null
            try
            {
                # Generate an automatic filename if filename is not supplied
                if (!$fileName)
                {
                    $fileName = "$([System.IO.Path]::GetFileName($logFolder))-$((Get-Date).ToString('yyyyMMddhhmmss')).zip"
                }

                if ($destinationPath)
                {
                    $zipFile = Join-Path $destinationPath $fileName

                    if (!(Test-Path $destinationPath))
                    {
                        mkdir $destinationPath > $null
                    }
                }
                else
                {
                    $zipFile = Join-Path ([IO.Path]::GetTempPath()) ('{0}.zip' -f $fileName)
                }

                # Choose appropriate implementation based on CLR version
                if ($PSVersionTable.CLRVersion.Major -lt 4)
                {
                    Copy-ToZipFileUsingShell -zipfilename $zipFile -itemToAdd $tempPath
                    $content = Get-Content $zipFile | Out-String
                }
                else
                {
                    Add-Type -AssemblyName System.IO.Compression.FileSystem > $null
                    [IO.Compression.ZipFile]::CreateFromDirectory($tempPath, $zipFile) > $null
                    $content = Get-Content -Raw $zipFile
                }
            }
            catch [Exception]
            {
                $caughtError = $_
            }

            if ($ReturnValue -eq 'Path')
            {
                # Don't return content if we don't need it
                return @{
                    Content     = $null
                    Error       = $caughtError
                    zipFilePath = $zipFile
                }
            }
            else
            {
                return @{
                    Content     = $content
                    Error       = $caughtError
                    zipFilePath = $zipFile
                }
            }
        } -argumentlist @($sourceFolder, $destinationPath, $fileName, $ReturnValue) -ErrorVariable zipInvokeError


        if ($zipInvokeError -or $resultTable.Error)
        {
            if ($attempts -lt 5)
            {
                Write-Debug "An error occured trying to zip $sourceFolder .  Will retry..."
                Start-Sleep -Seconds $attempts
            }
            else
            {
                if ($resultTable.Error)
                {
                    $lastError = $resultTable.Error
                }
                else
                {
                    $lastError = $zipInvokeError[0]
                }

                Write-Warning "An error occured trying to zip $sourceFolder .  Aborting."
                Write-ErrorInfo -ErrorObject $lastError -WriteWarning

            }
        }
        else
        {
            $gotZip = $true
        }
    }

    if ($ReturnValue -eq 'Path')
    {
        $result = $resultTable.zipFilePath
    }
    else
    {
        $result = $resultTable.content
    }

    return $result
}
