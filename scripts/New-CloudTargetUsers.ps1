#Requires -Version 7.0
<#
.SYNOPSIS
  Create CLOUD-ONLY UNLICENSED MailUser objects in target tenant (NOT plain Graph users).
.DESCRIPTION
  Microsoft native orchestrated mailbox migration REQUIRES MailUser objects in the target.
  Creates an Exchange Online MailUser with routing address to source, then disables sign-in
  via Graph. Uses random ephemeral password that is deliberately never printed or saved.
  New ExchangeGUID/x500/ArchiveGUID attributes are populated LATER via official CTIM.
  The approved mapping must contain sourcePrimarySMTP for each user; never infer from UPN.
  Not a password or MFA migration. Use controlled TAP or reset at cutover.
#>
[CmdletBinding()]
param(
 [Parameter(Mandatory)][guid]$TargetTenantId,
 [Parameter(Mandatory)][string]$TargetOrganization,
 [Parameter(Mandatory)][string]$MappingCsv,
 [Parameter(Mandatory)][string]$TargetStagingDomain,
 [Parameter(Mandatory)][string]$OutputCsv,
 [switch]$Execute,
 [string]$ApprovalPhrase
)
$ErrorActionPreference='Stop'
if($TargetStagingDomain -notmatch '^[A-Za-z0-9.-]+\.onmicrosoft\.com$'){throw 'Must use target onmicrosoft.com staging domain.'}
$rows=@(Import-Csv $MappingCsv)
if($rows.Count -eq 0){throw 'No users.'}
$ids=[System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach($r in $rows){
 $tmpId=[guid]::Empty
 if(-not [guid]::TryParse($r.sourceId,[ref]$tmpId)){throw 'Source ID invalid.'}
 if($r.targetId){throw "Already mapped target $($r.targetUPN); must not duplicate."}
 if($r.targetUPN -notmatch ('^[^@\s]+@'+[regex]::Escape($TargetStagingDomain)+'$')){throw 'Invalid target staging UPN.'}
 if($r.sourcePrimarySMTP -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$'){throw "Missing verified sourcePrimarySMTP for $($r.sourceUPN); export source Exchange inventory first."}
 if(-not $ids.Add($r.targetUPN)){throw 'Duplicate target UPN.'}
}
if(-not $Execute){Write-Host "PREVIEW: $($rows.Count) cloud-only UNLICENSED MailUsers would be created in $TargetTenantId; sign-in to be disabled. NO writes.";return}
if(@($rows|Where-Object {$_.approved -cne 'true'}).Count -gt 0){throw 'All target mappings require approved=true before creating any MailUsers.'}
if($ApprovalPhrase -cne "CREATE-MAILUSERS:$TargetTenantId"){throw 'BLOCKED: explicit approval phrase required.'}
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Connect-MgGraph -TenantId $TargetTenantId -Scopes @('User.ReadWrite.All','Organization.Read.All') -NoWelcome
if((Get-MgContext).TenantId -ne $TargetTenantId.ToString()){throw 'Wrong Graph tenant.'}
$org=Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/organization?$select=verifiedDomains' -OutputType PSObject
$verified=@($org.value[0].verifiedDomains|ForEach-Object {$_.name})
if($TargetStagingDomain -notin $verified){throw 'Staging domain not verified in target.'}
Connect-ExchangeOnline -Organization $TargetOrganization -ShowBanner:$false
$alphabet='abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#%?'
function New-EphemeralPassword {
 $chars=for($i=0;$i -lt 34;$i++){$alphabet[[System.Security.Cryptography.RandomNumberGenerator]::GetInt32($alphabet.Length)]}
 ConvertTo-SecureString ('aA7!'+(-join $chars)) -AsPlainText -Force
}
 $partialFailure=$null
try {
 foreach($r in $rows){
  try {
   $upn=$r.targetUPN
   # Avoid ambiguous overwrite: check both directory and Exchange.
   $safeUpn=$upn.Replace("'","''")
   $existing=Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/users?`$filter=userPrincipalName eq '$safeUpn'&`$select=id") -OutputType PSObject
   if($existing.value -and @($existing.value).Count -gt 0){throw 'Target UPN exists. Resolve identity mapping manually.'}
   $local=($upn -split '@')[0]
   $display=($local -replace '[._-]',' ').Trim()
   $created=New-MailUser -MicrosoftOnlineServicesID $upn -PrimarySmtpAddress $upn -ExternalEmailAddress $r.sourcePrimarySMTP -Name $display -Password (New-EphemeralPassword) -ErrorAction Stop
   $targetId=''
   for($attempt=0;$attempt -lt 6;$attempt++){
    $lookup=Invoke-MgGraphRequest -Method GET -Uri ("https://graph.microsoft.com/v1.0/users?`$filter=userPrincipalName eq '$safeUpn'&`$select=id,userPrincipalName") -OutputType PSObject
    if($lookup.value -and @($lookup.value).Count -gt 0){$targetId=$lookup.value[0].id;break}
    Start-Sleep -Seconds 3
   }
   if(-not $targetId){throw 'MailUser created but not yet visible in Graph; check replication and disable immediately before proceeding.'}
   Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/users/$targetId" -Body '{"accountEnabled":false}' -ContentType 'application/json' | Out-Null
   $r.targetId=$targetId
   $r.notes='MailUser created, unlicensed, sign-in disabled, ephemeral password not saved; run CTIM before licensing'
   Write-Host "Created unlicensed MailUser, sign-in disabled: $upn"
  } catch {
   $partialFailure = "STOPPED at $($r.targetUPN): $($_.Exception.Message). A partial object may exist; inspect both tenants before any re-run."
   Write-Warning $partialFailure
   break
  }
 }
} finally {Disconnect-ExchangeOnline -Confirm:$false}
$parent=Split-Path -Parent $OutputCsv
if($parent){New-Item -ItemType Directory -Force -Path $parent|Out-Null}
$rows|Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding utf8
Write-Warning "Private mapping output: $OutputCsv. Review every object manually; no credentials written. Mapping approval and CTIM still required."

if($partialFailure){throw $partialFailure}
