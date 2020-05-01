#
# Checks if this machine is a Server SKU
#
function Test-ServerSku
{
    [CmdletBinding()]
    $os = Get-CimInstance -ClassName  Win32_OperatingSystem
    $isServerSku = ($os.ProductType -ne 1)
}
