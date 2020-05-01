#Wrapper over Get-WinEvent, that will call into a computer if required.
function Get-WinEvent
{
    $resultArray = ""
    try
    {
        if ($script:UsingComputerName)
        {
            if ($script:ThisCredential)
            {
                $resultArray = Microsoft.PowerShell.Diagnostics\Get-WinEvent @args -ComputerName $script:ThisComputerName -Credential $script:ThisCredential
            }
            else
            {
                $resultArray = Microsoft.PowerShell.Diagnostics\Get-WinEvent @args -ComputerName $script:ThisComputerName
            }
        }
        else
        {
            $resultArray = Microsoft.PowerShell.Diagnostics\Get-WinEvent @args
        }
    }
    catch
    {
        LogDscDiagnostics -Error "Get-Winevent failed with error : $_ "
        throw "Cannot read events from computer $script:ThisComputerName. Please check if the firewall is enabled. Run this command in the remote machine to enable firewall for remote administration : New-NetFirewallRule -Name 'Service RemoteAdmin' -Action Allow "
    }

    return $resultArray
}
