# Change log for xDscDiagnostics

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added automatic release with a new CI pipeline.

### Fixed

- Fixes #52: Error 'Index operation failed; the array index evaluated to null.'

## [2.7.0.0] - 2018-06-13

- Fixed help formatting.

## [2.6.0.0] - 2016-12-14

- Added JobId parameter set to Get-xDscConfiguration
- Added IIS binding collection

## [2.5.0.0] - 2016-09-21

- Added ability for New-xDscDiagnosticsZip to only collect the `xDscDiagnosticsZipDataPoint` collection you specify by data point or by group (called target).
- Added Get-xDscDiagnosticsZipDataPoint
- Added ability for New-xDscDiagnosticsZip to collect IIS and HTTPErr logs

## [2.4.0.0] - 2016-08-10

- Added collection of OData logs to New-xDscDiagnosticsZip
- Converted appveyor.yml to install Pester from PSGallery instead of from Chocolatey.

## [2.3.0.0] - 2016-03-30

- Renamed Get-xDscDiagnosticsZip to New-xDscDiagnosticsZip CmdLet and aliased to Get-xDscDiagnosticsZip to prevent breaks
- Added the following datapoint to New-xDscDiagnosticsZip:
  - Collected local machine cert thumbprints
  - Collected installed DSC resource version and path information
  - Collected System event log
- Added more detailed tests for New-xDscDiagnosticsZip
- Added Unprotect-xDscConfigurtion to decrypt current, pending or previous mofs

## [2.2.0.0] - 2016-03-03

- Add the Get-xDscConfigurationDetail cmdlet

## [2.1.0.0] - 2016-02-02

- Add the Get-xDscDiagnosticsZip CmdLet

## [2.0.0.0] - 2015-04-17

- Release with bug fixes and the following cmdlets
  - Get-xDscOperation
  - Trace-xDscOperation
  - Update-xDscEventLogStatus

## [1.0.0.0] - 2015-04-15

- Initial release with the following cmdlets
  - Get-xDscOperation
  - Trace-xDscOperation
