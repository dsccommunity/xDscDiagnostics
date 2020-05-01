#
# Verifies if Pull Server is installed on this machine
#
function Test-PullServerPresent
{
    [CmdletBinding()]

    $isPullServerPresent = $false;

    $isServerSku = Test-ServerSku

    if ($isServerSku)
    {
        Write-Verbose "This is a Server machine"
        $website = Get-WebSite PSDSCPullServer -erroraction silentlycontinue
        if ($website -ne $null)
        {
            $isPullServerPresent = $true
        }
    }

    Write-Verbose "This is not a pull server"
    return $isPullServerPresent
}
