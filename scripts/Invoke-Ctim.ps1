#Requires -Version 7.0
<#
 Official CTIM phased wrapper; does not combine source/target tenant credentials.
 Run in a FRESH PowerShell console: Microsoft warns CTIM token acquisition can conflict
 with concurrent Graph/Exchange sessions. Each phase requires separate tenant sign-in.
 Command refs: https://learn.microsoft.com/en-us/microsoft-365/migration/cross-tenant-identity-mapping
#>
[CmdletBinding()]
param(
 [Parameter(Mandatory)][ValidateSet('Bootstrap','SourceCopy','TargetAccept','TargetMap','TargetWrite','TargetReport')][string]$Phase,
 [Parameter(Mandatory)][guid]$CurrentTenantId,
 [Parameter(Mandatory)][guid]$OtherTenantId,
 [guid]$SourceScopeSecurityGroupId,
 [guid]$RequestId,
 [switch]$Execute,
 [string]$ApprovalPhrase
)
$ErrorActionPreference='Stop'
if($CurrentTenantId -eq $OtherTenantId){throw 'Source and target must differ.'}
$sourceActions=@('SourceCopy')
$targetActions=@('TargetAccept','TargetMap','TargetWrite','TargetReport')
if(-not $Execute){
 Write-Host "CTIM preview: phase=$Phase; currentTenant=$CurrentTenantId; otherTenant=$OtherTenantId; interactive sign-in required."
 Write-Host 'Run in a fresh PowerShell window with official CrossTenantIdentityMapping module installed.'
 return
}
if($ApprovalPhrase -cne "CTIM:$($CurrentTenantId):$Phase"){throw 'BLOCKED: exact CTIM tenant/phase approval required.'}
Import-Module CrossTenantIdentityMapping -ErrorAction Stop
switch($Phase){
 'Bootstrap' {
  Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
  Connect-MgGraph -TenantId $CurrentTenantId -Scopes 'Application.ReadWrite.All','RoleManagement.ReadWrite.Directory' -NoWelcome
  if((Get-MgContext).TenantId -ne $CurrentTenantId.ToString()){throw 'Wrong tenant!'}
  Add-CtimServicePrincipal
  Write-Warning 'Restart terminal before CTIM requests; use source or target admin per phase. Service principal consent is privileged.'
 }
 'SourceCopy' {
  if($SourceScopeSecurityGroupId -eq [guid]::Empty){throw 'Source security group ID required.'}
  New-CtimCopyRequest -SecurityGroupGuid $SourceScopeSecurityGroupId -TargetTenantGuid $OtherTenantId
 }
 'TargetAccept' {
  if($RequestId -eq [guid]::Empty){throw 'Source-generated request ID required.'}
  Get-CtimRequest -RequestID $RequestId
  Accept-CtimCopyRequest -RequestID $RequestId -SourceTenantGUID $OtherTenantId
 }
 'TargetMap' {New-CtimMapRequest -SourceTenantGuid $OtherTenantId}
 'TargetWrite' {
  Write-Warning 'Verify Get-CtimReport for ALL intended users with Mapped status. This operation stamps target MailUser routing/GUID properties.'
  New-CtimWriteRequest -SourceTenantGuid $OtherTenantId
 }
 'TargetReport' {Get-CtimReport -SourceTenantGuid $OtherTenantId}
}
