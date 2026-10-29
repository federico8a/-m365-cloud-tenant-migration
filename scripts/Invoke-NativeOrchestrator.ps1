#Requires -Version 7.0
<#
 Native Graph beta Migration Orchestrator for Exchange, OneDrive and Teams chats/meetings.
 Official doc: https://learn.microsoft.com/en-us/microsoft-365/migration/migration-orchestrator-5-running-migration
 WARNING: Graph /beta is subject to change and Microsoft does not support beta APIs for production app use.
#>
[CmdletBinding()]
param(
 [ValidateSet('Preview','Create','Validate','Status','Migrate')][string]$Action='Preview',
 [Parameter(Mandatory)][string]$ConfigPath,
 [string]$MappingCsv,
 [string]$CutoverUtc,
 [string]$JobId,
 [switch]$Execute,
 [string]$ApprovalPhrase
)
$ErrorActionPreference='Stop'
$config=Get-Content $ConfigPath -Raw | ConvertFrom-Json
if ($config.sourceTenantId -eq $config.targetTenantId){throw 'Source and target tenants must differ.'}
if($Action -in @('Preview','Create')){
 if(-not $MappingCsv){throw 'MappingCsv required.'}
 if(-not $CutoverUtc){throw 'CutoverUtc required.'}
 $parsed=[datetimeoffset]::MinValue
 if(-not [datetimeoffset]::TryParse($CutoverUtc,[ref]$parsed)){throw 'CutoverUtc must be ISO-8601 UTC.'}
 if($parsed.Offset.TotalMinutes -ne 0){throw 'CutoverUtc must be UTC (+00:00 or Z).'}
 if($parsed -le [datetimeoffset]::UtcNow){throw 'Cutover date must be in the future.'}
 $rows=@(Import-Csv $MappingCsv)
 if($rows.Count -lt 1 -or $rows.Count -gt 100){throw 'Pilot/job must contain 1–100 users (conservative Microsoft Orchestrator maximum).'}
 if(@($rows | Where-Object {$_.approved -ne 'true' -or $_.targetId -notmatch '^[0-9a-fA-F-]{36}$'}).Count -gt 0){throw 'Every mapping needs approved=true and a real targetId GUID.'}
 if(@($rows | Group-Object targetId | Where-Object Count -gt 1).Count -gt 0){throw 'Duplicate target object ID.'}
 $body=@{
  displayName=$config.batchName
  completeAfterDateTime=$parsed.UtcDateTime.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
  sourceTenantId=$config.sourceTenantId
  exchangeSettings=@{targetDeliveryDomain=$config.targetDeliveryDomain;sourceEndpoint=$config.migrationEndpointName}
  resources=@($rows | ForEach-Object {$_.targetId})
  resourceType='Users'
  workloads=@($config.migrationWorkloads)
 }
 if(@($body.workloads|Where-Object {$_ -notin @('Exchange','ODSP','Teams','Meeting')}).Count -gt 0){throw 'Unsupported Orchestrator workload.'}
 if($Action -eq 'Preview') { $body | ConvertTo-Json -Depth 10; return }
}
if($Action -in @('Validate','Status','Migrate') -and -not $JobId){throw 'JobId is required.'}
if($Action -ne 'Status'){
 if(-not $Execute -or $ApprovalPhrase -ne "APPROVED:$($config.targetTenantId)"){
  throw "BLOCKED: requires -Execute -ApprovalPhrase 'APPROVED:<TARGET-TENANT-ID>' under approved change control."
 }
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.Beta.Migrations -ErrorAction Stop
Connect-MgGraph -TenantId $config.targetTenantId -Scopes 'CrossTenantContentMigration.ReadWrite.All' -NoWelcome
if((Get-MgContext).TenantId -ne $config.targetTenantId){throw 'Refusing operation in wrong tenant.'}
switch($Action){
 'Create'   {New-MgBetaCrossTenantMigrationJob -BodyParameter $body | ConvertTo-Json -Depth 20}
 'Validate' {Test-MgBetaCrossTenantMigrationJob -CrossTenantMigrationJobId $JobId}
 'Status'   {Get-MgBetaCrossTenantMigrationJob -CrossTenantMigrationJobId $JobId | ConvertTo-Json -Depth 30}
 'Migrate'  {
  $job=Get-MgBetaCrossTenantMigrationJob -CrossTenantMigrationJobId $JobId
  if($job.Status -ne 'ValidatePassed'){throw "Not validated: $($job.Status). Revalidate if older than 7 days."}
  Move-MgBetaCrossTenantMigrationJob -CrossTenantMigrationJobId $JobId
 }
}
