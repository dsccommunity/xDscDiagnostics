
function LogDscDiagnostics
{
    param($text , [Switch]$Error , [Switch]$Verbose , [Switch]$Warning)
    $formattedText = "XDscDiagnostics : $text"
    if ($Error)
    {
        Write-Error   $formattedText
    }
    elseif ($Verbose)
    {
        Write-Verbose $formattedText
    }

    elseif ($Warning)
    {
        Write-Warning $formattedText
    }

}
