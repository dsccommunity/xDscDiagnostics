# decrypt one of the lcm mof
function Unprotect-xDscConfiguration
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet('Current', 'Pending', 'Previous')]
        $Stage
    )

    Add-Type -AssemblyName System.Security

    $path = "$env:windir\System32\Configuration\$stage.mof"

    if (Test-Path $path)
    {
        $secureString = Get-Content $path -Raw

        $enc = [system.Text.Encoding]::Default

        $data = $enc.GetBytes($secureString)

        $bytes = [System.Security.Cryptography.ProtectedData]::Unprotect( $data, $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine )

        $enc = [system.text.encoding]::Unicode

        $enc.GetString($bytes)
    }
    else
    {
        throw (New-Object -TypeName 'System.IO.FileNotFoundException' -ArgumentList @("The stage $stage was not found"))
    }
}
