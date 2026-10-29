#Requires -Version 7.0
<#
.SYNOPSIS
  Read-only Microsoft Graph tenant inventory, preserving immutable Entra object IDs.
.DESCRIPTION
  Run separately in Tenant A and Tenant B. Calls Graph v1.0 only, no writes.
  Partial 403 permissions produce a warning file; they are not silently counted as empty inventories.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)][guid]$TenantId,
  [Parameter(Mandatory)][string]$OutputDirectory,
  [switch]$SkipIntune
)
$ErrorActionPreference = 'Stop'
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$scopes = @('User.Read.All','Group.Read.All','Application.Read.All','Directory.Read.All','Policy.Read.All','Organization.Read.All','Device.Read.All')
if (-not $SkipIntune) { $scopes += 'DeviceManagementConfiguration.Read.All'; $scopes += 'DeviceManagementManagedDevices.Read.All'; $scopes += 'DeviceManagementApps.Read.All' }
Connect-MgGraph -TenantId $TenantId -Scopes $scopes -NoWelcome
if ((Get-MgContext).TenantId -ne $TenantId.ToString()) { throw 'Wrong Graph tenant context.' }
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$OutputDirectory = (Resolve-Path $OutputDirectory).Path
$errors = [System.Collections.Generic.List[object]]::new()

function Get-PagedGraph([string]$Uri) {
  $records = [System.Collections.Generic.List[object]]::new()
  $next = "https://graph.microsoft.com$Uri"
  while ($next) {
    $response = Invoke-MgGraphRequest -Method GET -Uri $next -OutputType PSObject
    foreach ($item in @($response.value)) { if ($null -ne $item) { $records.Add($item) } }
    $next = $response.'@odata.nextLink'
  }
  return $records.ToArray()
}

$endpoints = [ordered]@{
  'organization'         = '/v1.0/organization?$select=id,displayName,verifiedDomains'
  'users'                = '/v1.0/users?$select=id,userPrincipalName,displayName,mail,accountEnabled,onPremisesSyncEnabled,assignedLicenses,proxyAddresses,userType'
  'groups'               = '/v1.0/groups?$select=id,displayName,mail,groupTypes,mailEnabled,securityEnabled,description,proxyAddresses'
  'applications'         = '/v1.0/applications?$select=id,appId,displayName,identifierUris,signInAudience,requiredResourceAccess,web,spa,publicClient'
  'servicePrincipals'    = '/v1.0/servicePrincipals?$select=id,appId,displayName,servicePrincipalType,appRoleAssignmentRequired,accountEnabled,preferredSingleSignOnMode'
  'subscribedSkus'       = '/v1.0/subscribedSkus'
  'devices'              = '/v1.0/devices?$select=id,deviceId,displayName,operatingSystem,trustType,isManaged'
  'conditionalAccess'    = '/v1.0/identity/conditionalAccess/policies'
  'namedLocations'       = '/v1.0/identity/conditionalAccess/namedLocations'
  'authenticationPolicy' = '/v1.0/policies/authenticationMethodsPolicy'
}
if (-not $SkipIntune) {
  $endpoints['intuneDeviceConfigurations'] = '/v1.0/deviceManagement/deviceConfigurations'
  $endpoints['intuneCompliancePolicies'] = '/v1.0/deviceManagement/deviceCompliancePolicies'
  $endpoints['intuneConfigurationPolicies'] = '/v1.0/deviceManagement/configurationPolicies'
  $endpoints['intuneManagedDevices'] = '/v1.0/deviceManagement/managedDevices'
  $endpoints['intuneMobileApps'] = '/v1.0/deviceAppManagement/mobileApps'
  $endpoints['intuneEnrollmentConfigurations'] = '/v1.0/deviceManagement/deviceEnrollmentConfigurations'
}
foreach ($name in $endpoints.Keys) {
  try {
    $records = @(Get-PagedGraph -Uri $endpoints[$name])
    $records | ConvertTo-Json -Depth 60 | Set-Content -Path (Join-Path $OutputDirectory "$name.json") -Encoding utf8
    if ($records.Count -eq 0) { '[]' | Set-Content (Join-Path $OutputDirectory "$name.json") -Encoding utf8 }
    Write-Host "$name : $($records.Count)"
  } catch {
    $errors.Add([pscustomobject]@{workload=$name;endpoint=$endpoints[$name];error=$_.Exception.Message})
    Write-Warning "Unable to inventory $name. See collection-errors.json."
  }
}
$errors | ConvertTo-Json -Depth 8 | Set-Content (Join-Path $OutputDirectory 'collection-errors.json') -Encoding utf8
if ($errors.Count -eq 0) { '[]' | Set-Content (Join-Path $OutputDirectory 'collection-errors.json') -Encoding utf8 }
[pscustomobject]@{tenantId=$TenantId.ToString();collectedUtc=(Get-Date).ToUniversalTime().ToString('o');failedCollections=$errors.Count;source='Microsoft Graph v1.0'} |
  ConvertTo-Json | Set-Content (Join-Path $OutputDirectory '_manifest.json') -Encoding utf8
if ($errors.Count -gt 0) { Write-Warning "Inventory incomplete: $($errors.Count) endpoint(s) failed." }
