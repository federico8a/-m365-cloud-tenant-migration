#Requires -Version 7.0
<#
.SYNOPSIS
  One terminal entry point for safe migration PLANNING. No step silently performs a full M365 move.
.EXAMPLE
  ./scripts/Invoke-M365Migration.ps1 -Phase Assess -ConfigPath config/local.json -MappingCsv output/identity-map.csv
#>
[CmdletBinding()]
param(
 [Parameter(Mandatory)][ValidateSet('InventorySource','InventoryTarget','IdentityMap','Assess','DnsAudit','OrchestratorPreview')][string]$Phase,
 [Parameter(Mandatory)][string]$ConfigPath,
 [string]$MappingCsv='./output/identity-map.csv',
 [string]$CutoverUtc
)
$ErrorActionPreference='Stop'
$c=Get-Content $ConfigPath -Raw|ConvertFrom-Json
$root=Split-Path -Parent $PSScriptRoot
if([guid]$c.sourceTenantId -eq [guid]$c.targetTenantId){throw 'Same source/target tenant is not allowed.'}
switch($Phase){
 'InventorySource' {& "$PSScriptRoot/Export-GraphInventory.ps1" -TenantId $c.sourceTenantId -OutputDirectory "$root/output/source"}
 'InventoryTarget' {& "$PSScriptRoot/Export-GraphInventory.ps1" -TenantId $c.targetTenantId -OutputDirectory "$root/output/target"}
 'IdentityMap' {& "$PSScriptRoot/New-IdentityMap.ps1" -SourceUsers "$root/output/source/users.json" -TargetStagingDomain $c.targetStagingDomain -OutputPath $MappingCsv}
 'Assess' {
   $python=if(Get-Command python3 -ErrorAction SilentlyContinue){'python3'}else{'python'}
   & $python "$root/tools/assess.py" --source "$root/output/source" --target "$root/output/target" --mapping $MappingCsv --output "$root/output/readiness.json"
   if($LASTEXITCODE -ne 0){throw "Assessment failed with code $LASTEXITCODE"}
 }
 'DnsAudit' {& "$PSScriptRoot/Test-DnsReadiness.ps1" -Domain $c.cutoverDomain -OutputPath "$root/output/dns-audit.json"}
 'OrchestratorPreview' {
   if(-not $CutoverUtc){throw 'CutoverUtc is required.'}
   & "$PSScriptRoot/Invoke-NativeOrchestrator.ps1" -Action Preview -ConfigPath $ConfigPath -MappingCsv $MappingCsv -CutoverUtc $CutoverUtc
 }
}
