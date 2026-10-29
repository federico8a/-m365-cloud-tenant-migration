#Requires -Version 7.0
<#
.SYNOPSIS
  Compatibility shim for legacy read-only command names. Use ../main.ps1 for all
  new workflows, including approved mutating stages.
#>
[CmdletBinding()]
param(
 [Parameter(Mandatory)][ValidateSet('InventorySource','InventoryTarget','IdentityMap','Assess','DnsAudit','OrchestratorPreview')][string]$Phase,
 [Parameter(Mandatory)][string]$ConfigPath,
 [string]$MappingCsv,
 [string]$CutoverUtc
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$stage = if ($Phase -eq 'OrchestratorPreview') { 'MigrationPreview' } else { $Phase }
Write-Warning 'Deprecated wrapper. Use ./main.ps1 -Stage <stage> directly; migration stages are only exposed there.'
$argsList = @('-Stage',$stage,'-ConfigPath',$ConfigPath)
if ($MappingCsv) { $argsList += @('-MappingCsv',$MappingCsv) }
if ($CutoverUtc) { $argsList += @('-CutoverUtc',$CutoverUtc) }
& (Join-Path $root 'main.ps1') @argsList
