#
# Tests if a parameter is a container, to be used in a ValidateScript attribute
#
function Test-ContainerParameter
{
    [CmdletBinding()]
    param
    (
        [string] $Path,
        [string] $Name = 'Path'
    )

    if (!(Test-Path $Path -PathType Container))
    {
        throw "$Name parameter must be a valid container."
    }

    return $true
}
