# Gets the Json details for a configuration status
function Get-xDscConfigurationDetail
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValuefromPipeline = $true, ParameterSetName = "ByValue")]
        [ValidateScript( {
                if ($_.CimClass.CimClassName -eq 'MSFT_DSCConfigurationStatus')
                {
                    return $true
                }
                else
                {
                    throw 'Must be a configuration status object'
                }
            })]
        $ConfigurationStatus,

        [Parameter(Mandatory = $true, ParameterSetName = "ByJobId")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {
                [System.Guid] $jobGuid = [System.Guid]::Empty
                if ([System.Guid]::TryParse($_, ([ref] $jobGuid)))
                {
                    return $true
                }
                else
                {
                    throw 'JobId must be a valid GUID'
                }
            })]
        [string] $JobId
    )
    process
    {
        [bool] $hasJobId = $false
        [string] $id = ''
        if ($null -ne $ConfigurationStatus)
        {
            $id = $ConfigurationStatus.JobId
        }
        else
        {
            [System.Guid] $jobGuid = [System.Guid]::Parse($JobId)
            # ensure the job id string has the expected leading and trailing '{', '}' characters.
            $id = $jobGuid.ToString('B')
        }

        $detailsFiles = Get-ChildItem -Path "$env:windir\System32\Configuration\ConfigurationStatus\$id-?.details.json" -ErrorAction 'SilentlyContinue'
        if ($detailsFiles)
        {
            foreach ($detailsFile in $detailsFiles)
            {
                Write-Verbose -Message "Getting details from: $($detailsFile.FullName)"
                (Get-Content -Encoding Unicode -raw $detailsFile.FullName) |
                    ConvertFrom-Json |
                        Foreach-Object {
                            Write-Output $_
                        }
            }
        }
        elseif ($null -ne $ConfigurationStatus)
        {
            if ($($ConfigurationStatus.type) -eq 'Consistency')
            {
                Write-Warning -Message "DSC does not produced details for job type: $($ConfigurationStatus.type); id: $($ConfigurationStatus.JobId)"
            }
            else
            {
                Write-Error -Message "Cannot find detail for job type: $($ConfigurationStatus.type); id: $($ConfigurationStatus.JobId)"
            }
        }
        else
        {
            throw "Cannot find configuration details for job $id"
        }
    }
}
