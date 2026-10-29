#Requires -Version 7.0
<# Confirm that target migration users are MailUsers (NOT mailboxes). Never mutate. #>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$Organization,[Parameter(Mandatory)][string]$MappingCsv,[Parameter(Mandatory)][string]$OutputPath)
$ErrorActionPreference='Stop'
Import-Module ExchangeOnlineManagement -ErrorAction Stop
$rows=@(Import-Csv $MappingCsv)
Connect-ExchangeOnline -Organization $Organization -ShowBanner:$false
try {
 $results=foreach($r in $rows){
  $upn=$r.targetUPN
  $blockers=[System.Collections.Generic.List[string]]::new()
  $mailbox=Get-EXOMailbox -Identity $upn -ErrorAction SilentlyContinue
  if($mailbox){$blockers.Add('Target mailbox ALREADY exists: native mailbox migration blocked.')}
  $mailUser=Get-MailUser -Identity $upn -ErrorAction SilentlyContinue
  if(-not $mailUser){$blockers.Add('Target MailUser missing; run official CTIM prep.')}
  if($mailUser){
   if(-not $mailUser.ExchangeGuid -or $mailUser.ExchangeGuid -eq [guid]::Empty){$blockers.Add('ExchangeGuid missing; identity mapping/CTIM incomplete.')}
   if(-not $mailUser.ExternalEmailAddress){$blockers.Add('ExternalEmailAddress missing.')}
  }
  [pscustomobject]@{targetUPN=$upn;targetId=$r.targetId;hasMailbox=[bool]$mailbox;
    hasMailUser=[bool]$mailUser;exchangeGuid=if($mailUser){$mailUser.ExchangeGuid.ToString()}else{''};
    blockers=@($blockers);status=if($blockers.Count){'BLOCKED'}else{'EXCHANGE_READY_ONLY'} }
 }
 $parent=Split-Path -Parent $OutputPath
 if($parent){New-Item -ItemType Directory -Force -Path $parent|Out-Null}
 $results|ConvertTo-Json -Depth 10|Set-Content -Path $OutputPath -Encoding utf8
 $count=@($results|Where-Object status -eq 'BLOCKED').Count
 Write-Host "Exchange-only readiness: $count blocked / $($results.Count) total. OneDrive site absence and native CTIM status require additional checks."
} finally {Disconnect-ExchangeOnline -Confirm:$false}
