#Requires -Version 7.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$Domain,[Parameter(Mandatory)][string]$OutputPath)
$ErrorActionPreference='Stop'
$types=@('MX','TXT','CNAME','NS')
$records=foreach($t in $types){
 try {Resolve-DnsName -Name $Domain -Type $t -ErrorAction Stop | Select-Object @{Name='queriedDomain';Expression={$Domain}},Name,Type,NameHost,MailExchange,Strings,TTL} }
 catch { [pscustomobject]@{queriedDomain=$Domain;Type=$t;error=$_.Exception.Message} }
}
$parent=Split-Path -Parent $OutputPath
if($parent){New-Item -Path $parent -ItemType Directory -Force|Out-Null}
$records | ConvertTo-Json -Depth 10 | Set-Content $OutputPath -Encoding utf8
Write-Warning 'DNS audit only. No DNS modification performed. Also export provider zone for DKIM/DMARC/Autodiscover/subdomains.'
