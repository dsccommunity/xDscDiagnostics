#
# Gathers diagnostics for DSC and the DSC Extension into a zipfile
# if specified, in the specified path
# if specified, in the specified filename
# on the specified session, if the session is not specified
# a session to the local machine will be used
#
function New-xDscDiagnosticsZip
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = 'default')]
    [Alias('Get-xDscDiagnosticsZip')]
    param
    (
        [Parameter(ParameterSetName = 'default')]
        [Parameter(ParameterSetName = 'includedDataPoints')]
        [Parameter(ParameterSetName = 'includedTargets')]
        [System.Management.Automation.Runspaces.PSSession] $Session,

        [Parameter(ParameterSetName = 'default')]
        [Parameter(ParameterSetName = 'includedDataPoints')]
        [Parameter(ParameterSetName = 'includedTargets')]
        [string] $destinationPath,

        [Parameter(ParameterSetName = 'default')]
        [Parameter(ParameterSetName = 'includedDataPoints')]
        [Parameter(ParameterSetName = 'includedTargets')]
        [string] $filename,

        [Parameter(ParameterSetName = 'includedDataPoints', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            foreach ($point in $_)
            {
                if ($_.pstypenames -notcontains $script:datapointTypeName)
                {
                    throw 'IncluedDataPoint must be an array of xDscDiagnostics datapoint objects.'
                }
            }

            return $true
        })]
        [object[]] $includedDataPoint
    )
    dynamicparam
    {
        $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()

        $dataPointTargetsParametereAttribute = [System.Management.Automation.ParameterAttribute]::new()
        $dataPointTargetsParametereAttribute.Mandatory = $true
        $dataPointTargetsParametereAttribute.ParameterSetName = 'includedTargets'
        $attributeCollection.Add($dataPointTargetsParametereAttribute)

        $validateSetAttribute = [System.Management.Automation.ValidateSetAttribute]::new([string[]]$script:validTargets)

        $attributeCollection.Add($validateSetAttribute)
        $dataPointTargetsParam = New-Object System.Management.Automation.RuntimeDefinedParameter('DataPointTarget', [String[]], $attributeCollection)

        $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        $paramDictionary.Add('DataPointTarget', $dataPointTargetsParam)
        return $paramDictionary
    }

    process
    {
        [string[]] $dataPointTarget = $PSBoundParameters.DataPointTarget
        $dataPointsToCollect = @{ }
        switch ($pscmdlet.ParameterSetName)
        {
            "includedDataPoints"
            {
                foreach ($dataPoint in $includedDataPoint)
                {
                    $dataPointsToCollect.Add($dataPoint.Name, $script:dataPoints.($dataPoint.Name))
                }
            }
            "includedTargets"
            {
                foreach ($key in $script:dataPoints.keys)
                {
                    $dataPoint = $script:dataPoints.$key
                    if ($dataPointTarget -icontains $dataPoint.Target)
                    {
                        $dataPointsToCollect.Add($key, $dataPoint)
                    }
                }
            }
            default
            {
                foreach ($key in $script:dataPoints.keys)
                {
                    $dataPoint = $script:dataPoints.$key
                    if ($script:defaultTargets -icontains $dataPoint.Target)
                    {
                        $dataPointsToCollect.Add($key, $dataPoint)
                    }
                }
            }
        }

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

        $privacyConfirmation = "Collecting the following information, which may contain private/sensative details including:"
        foreach ($key in $dataPointsToCollect.Keys)
        {
            $dataPoint = $dataPointsToCollect.$key
            $privacyConfirmation += [System.Environment]::NewLine
            $privacyConfirmation += ("`t{0}" -f $dataPoint.Description)
        }
        $privacyConfirmation += [System.Environment]::NewLine
        $privacyConfirmation += "This tool is provided for your convience, to ensure all data is collected as quickly as possible."
        $privacyConfirmation += [System.Environment]::NewLine
        $privacyConfirmation += "Are you sure you want to continue?"

        if ($pscmdlet.ShouldProcess($privacyConfirmation))
        {
            $tempPath = invoke-command -ErrorAction:Continue @invokeCommandParams -script {
                $ErrorActionPreference = 'stop'
                Set-StrictMode -Version latest
                $tempPath = Join-path $env:temp ([system.io.path]::GetRandomFileName())
                if (!(Test-Path $tempPath))
                {
                    mkdir $tempPath > $null
                }
                return $tempPath
            }
            Write-Verbose -message "tempPath: $tempPath"

            $collectedPoints = 0
            foreach ($key in $dataPointsToCollect.Keys)
            {
                $dataPoint = $dataPointsToCollect.$key
                if (!$dataPoint.Skip -or !(&$dataPoint.skip))
                {
                    Write-ProgressMessage  -Status "Collecting '$($dataPoint.Description)' ..." -PercentComplete ($collectedPoints / $script:dataPoints.Count)
                    $collected = Collect-DataPoint -dataPoint $dataPoint -invokeCommandParams $invokeCommandParams -Name $key
                    if (!$collected)
                    {
                        Write-Warning "Did not collect  '$($dataPoint.Description)'"
                    }
                }
                else
                {
                    Write-Verbose -Message "Skipping collecting '$($dataPoint.Description)' ..."
                }
                $collectedPoints ++
            }

            if (!$destinationPath)
            {
                Write-ProgressMessage  -Status 'Getting destinationPath ...' -PercentComplete 74
                $destinationPath = invoke-command -ErrorAction:Continue @invokeCommandParams -script {
                    $ErrorActionPreference = 'stop'
                    Set-StrictMode -Version latest
                    Join-path $env:temp ([system.io.path]::GetRandomFileName())
                }
            }

            Write-Debug -message "destinationPath: $destinationPath" -verbose
            $zipParams = @{
                sourceFolder    = $tempPath
                destinationPath = $destinationPath
                Session         = $session
                fileName        = $fileName
            }

            Write-ProgressMessage  -Status 'Zipping files ...' -PercentComplete 75
            if ($local)
            {
                $zip = Get-FolderAsZip @zipParams
                $zipPath = $zip
            }
            else
            {
                $zip = Get-FolderAsZip @zipParams -ReturnValue 'Content'
                if (!(Test-Path $destinationPath))
                {
                    mkdir $destinationPath > $null
                }
                $zipPath = (Join-path $destinationPath "$($session.ComputerName)-dsc-diags-$((Get-Date).ToString('yyyyMMddhhmmss')).zip")
                set-content -path $zipPath -value $zip
            }

            Start-Process $destinationPath
            Write-Verbose -message "Please send this zip file the engineer you have been working with.  The engineer should have emailed you instructions on how to do this: $zipPath" -verbose
            Write-ProgressMessage  -Completed
            return $zipPath
        }

    }
}
