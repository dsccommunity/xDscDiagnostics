

@{


moduleVersion = '2.7.0.0'
GUID = 'ef098cb4-f7e9-4763-b636-0cd9799e1c9a'

Author = 'Microsoft Corporation'
CompanyName = 'Microsoft Corporation'
Copyright = '(c) 2013 Microsoft Corporation. All rights reserved.'

Description = 'Module to help in reading details from DSC events'

PowerShellVersion = '4.0'

CLRVersion = '4.0'

FunctionsToExport = @("*")

AliasesToExport = '*'

NestedModules = @('xDscDiagnostics.psm1','CollectDscDiagnostics.psm1')

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('DesiredStateConfiguration', 'DSC', 'DSCResourceKit')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/PowerShell/xDscDiagnostics/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/PowerShell/xDscDiagnostics'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '* Fixed help formatting.

'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}




