#Requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$Domain,[Parameter(Mandatory)][string]$OutputPath)
$ErrorActionPreference='Stop'
$types=@('MX','TXT','CNAME','NS')
$resolver=Get-Command Resolve-DnsName -ErrorAction SilentlyContinue
$dig=if(-not $resolver){Get-Command dig -ErrorAction SilentlyContinue}else{$null}
if(-not $resolver -and -not $dig){throw 'DNS audit needs Resolve-DnsName (Windows) or dig (macOS/Linux, dnsutils/bind-utils). Install one and retry.'}
$records=foreach($t in $types){
 try {
  if($resolver){
   Resolve-DnsName -Name $Domain -Type $t -ErrorAction Stop | Select-Object @{Name='queriedDomain';Expression={$Domain}},Name,Type,NameHost,MailExchange,Strings,TTL
  } else {
   $answers=@(& $dig.Source '+time=3' '+tries=2' '+noall' '+answer' $Domain $t)
   if($LASTEXITCODE -ne 0){throw "dig exited with code $LASTEXITCODE"}
   [pscustomobject]@{queriedDomain=$Domain;Type=$t;rawAnswers=$answers}
  }
 } catch { [pscustomobject]@{queriedDomain=$Domain;Type=$t;error=$_.Exception.Message} }
}
$parent=Split-Path -Parent $OutputPath
if($parent){New-Item -Path $parent -ItemType Directory -Force|Out-Null}
if(@($records|Where-Object {$_.PSObject.Properties['error']}).Count -gt 0){throw 'One or more DNS lookups failed. Correct resolver/network and rerun DNS audit.'}
$records | ConvertTo-Json -Depth 10 | Set-Content $OutputPath -Encoding utf8
Write-Warning 'DNS audit only. No DNS modification performed. Also export provider zone for DKIM/DMARC/Autodiscover/subdomains.'
