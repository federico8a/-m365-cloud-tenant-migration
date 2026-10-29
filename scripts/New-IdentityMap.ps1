#Requires -Version 7.0
[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$SourceUsers,
 [Parameter(Mandatory)][string]$TargetStagingDomain,
 [string]$SourceMailboxes,
 [Parameter(Mandatory)][string]$OutputPath
)
$ErrorActionPreference='Stop'
if ($TargetStagingDomain -notmatch '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') { throw 'Invalid target staging domain.' }
$users=@(Get-Content $SourceUsers -Raw | ConvertFrom-Json)
$mailboxById=@{}
if($SourceMailboxes){
 foreach($mb in @(Get-Content $SourceMailboxes -Raw | ConvertFrom-Json)){
  if($mb.ExternalDirectoryObjectId){$mailboxById[$mb.ExternalDirectoryObjectId.ToString().ToLowerInvariant()]=$mb}
 }
}
$mapping=foreach($user in $users){
 if($user.onPremisesSyncEnabled -eq $true) { throw "BLOCKED hybrid identity detected: $($user.userPrincipalName)" }
 if($user.userType -eq 'Guest') { continue }
 $local=($user.userPrincipalName -split '@')[0]
 $mb=$mailboxById[$user.id.ToString().ToLowerInvariant()]
 $sourceSMTP=if($mb){$mb.PrimarySmtpAddress}else{''}
 [pscustomobject]@{sourceId=$user.id;sourceUPN=$user.userPrincipalName;sourcePrimarySMTP=$sourceSMTP;targetUPN="$local@$TargetStagingDomain";targetId='';approved='false';notes='Review alias collision and source SMTP; Exchange MailUser requires approved mapping'}
}
if(@($mapping | Group-Object targetUPN | Where-Object Count -gt 1).Count -gt 0) { throw 'Duplicate target UPN candidates. Stop and map manually.' }
$parent=Split-Path -Parent $OutputPath
if($parent -and -not(Test-Path $parent)){New-Item -ItemType Directory -Path $parent -Force | Out-Null}
$mapping | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding utf8
Write-Host "Created $(@($mapping).Count) proposed mappings. No users have been created. Human approval is mandatory."
