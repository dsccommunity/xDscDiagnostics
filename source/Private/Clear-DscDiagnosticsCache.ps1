function Clear-DscDiagnosticsCache
{
    LogDscDiagnostics -Verbose "Clearing Diagnostics Cache"
    $script:LatestGroupedEvents = @{ }
    $script:LatestEvent = @{ }
}
