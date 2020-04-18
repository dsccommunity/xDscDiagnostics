# Returns a list of datapoints which will be collected by
# New-xDscDiagnosticsZip
function Get-xDscDiagnosticsZipDataPoint
{
    foreach($key in $script:dataPoints.Keys)
    {
        $dataPoint = $script:dataPoints.$key
        $dataPointObj = ([PSCustomObject] @{
            Name = $key
            Description = $dataPoint.Description
            Target = $dataPoint.Target
        })
        $dataPointObj.pstypenames.Clear()
        $dataPointObj.pstypenames.Add($script:datapointTypeName)
        Write-Output $dataPointObj
    }
}
