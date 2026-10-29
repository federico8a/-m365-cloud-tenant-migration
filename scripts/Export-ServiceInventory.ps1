#Requires -Version 7.0
<# Read-only inventories for workloads with independent PowerShell management APIs. #>
[CmdletBinding()]
param(
 [Parameter(Mandatory)][guid]$TenantId,
 [Parameter(Mandatory)][string]$OutputDirectory,
 [string]$SPOAdminUrl,
 [switch]$SkipExchange,
 [switch]$SkipTeams,
 [switch]$SkipSharePoint
)
$ErrorActionPreference='Stop'
New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
function Save-Json($Name, $Value) {
 $path=Join-Path $OutputDirectory "$Name.json"
 @($Value) | ConvertTo-Json -Depth 40 | Set-Content $path -Encoding utf8
 if (-not (Test-Path $path) -or -not (Get-Content $path -Raw).Trim()) {'[]'|Set-Content $path}
}
if (-not $SkipExchange) {
 Import-Module ExchangeOnlineManagement -ErrorAction Stop
 Connect-ExchangeOnline -Organization $TenantId.ToString() -ShowBanner:$false
 try {
  Save-Json 'mailboxes' @(Get-EXOMailbox -ResultSize Unlimited -Properties ExchangeGuid,ArchiveGuid,RecipientTypeDetails,PrimarySmtpAddress,EmailAddresses,ExternalDirectoryObjectId,LitigationHoldEnabled)
  Save-Json 'distributionGroups' @(Get-DistributionGroup -ResultSize Unlimited | Select-Object DisplayName,PrimarySmtpAddress,ExternalDirectoryObjectId,ManagedBy,EmailAddresses)
  Save-Json 'mailContacts' @(Get-MailContact -ResultSize Unlimited | Select-Object DisplayName,PrimarySmtpAddress,ExternalEmailAddress)
  Save-Json 'transportRules' @(Get-TransportRule | Select-Object Name,State,Priority,Mode)
  Save-Json 'acceptedDomains' @(Get-AcceptedDomain | Select-Object Name,DomainName,DomainType,Default)
 } finally { Disconnect-ExchangeOnline -Confirm:$false }
}
if (-not $SkipTeams) {
 Import-Module MicrosoftTeams -ErrorAction Stop
 Connect-MicrosoftTeams -TenantId $TenantId
 $teams=@(Get-Team)
 Save-Json 'teams' ($teams | Select-Object GroupId,DisplayName,Description,Visibility,MailNickName)
 $channels=foreach ($team in $teams) {
  try { Get-TeamChannel -GroupId $team.GroupId | Select-Object @{Name='TeamId';Expression={$team.GroupId}},DisplayName,MembershipType } catch { Write-Warning "Channel inventory failed: $($team.GroupId): $_" }
 }
 Save-Json 'teamsChannels' @($channels)
 Disconnect-MicrosoftTeams | Out-Null
}
if (-not $SkipSharePoint) {
 if (-not $SPOAdminUrl) { throw 'SPOAdminUrl is required when SharePoint inventory is enabled.' }
 Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
 Connect-SPOService -Url $SPOAdminUrl
 Save-Json 'sharePointSites' @(Get-SPOSite -Limit All -IncludePersonalSite $true | Select-Object Url,Owner,Template,StorageUsageCurrent,GroupId,LockState,SharingCapability)
}
