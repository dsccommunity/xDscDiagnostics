#Function to get all dsc events in the event log - not exposed by the module
function Get-AllDscEvents
{
    #If you want a specific channel events, run it as Get-AllDscEvents
    param
    (
        [string[]]$ChannelType = @("Debug" , "Analytic" , "Operational") ,
        $OtherParameters = @{ }

    )
    if ($ChannelType.ToLower().Contains("operational"))
    {

        $operationalEvents = Get-WinEvent -LogName "$script:DscLogName/operational"  @OtherParameters -ea Ignore
        $allEvents = $operationalEvents

    }
    if ($ChannelType.ToLower().Contains("analytic"))
    {
        $analyticEvents = Get-WinEvent -LogName "$script:DscLogName/analytic" -Oldest  -ea Ignore @OtherParameters
        if ($analyticEvents -ne $null)
        {

            #Convert to an array type before adding another type - to avoid the error "Method invocation failed with no op_addition operator"
            $allEvents = [System.Array]$allEvents + $analyticEvents

        }

    }

    if ($ChannelType.ToLower().Contains("debug"))
    {
        $debugEvents = Get-WinEvent -LogName "$script:DscLogName/debug" -Oldest -ea Ignore @OtherParameters
        if ($debugEvents -ne $null)
        {
            $allEvents = [System.Array]$allEvents + $debugEvents

        }
    }

    return $allEvents
}
