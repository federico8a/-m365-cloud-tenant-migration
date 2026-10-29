#Requires -Version 7.0
<#
.SYNOPSIS
    Single supported terminal entry point for the cloud-only M365 Tenant A -> B migration toolkit.
.DESCRIPTION
    Dispatches to purpose-built scripts in ./scripts, using a workflow module for
    validation, tenant separation, and guarded execution. No hidden migrations.
    Running without arguments opens an interactive, approval-gated menu.
.EXAMPLE
    pwsh ./main.ps1 -Stage Plan -ConfigPath ./config/local.json
.EXAMPLE
    pwsh ./main.ps1 -Stage AllReadOnly -ConfigPath ./config/local.json -IncludeServices
.EXAMPLE
    pwsh ./main.ps1 -Stage MigrationPreview -ConfigPath ./config/local.json -CutoverUtc '2026-12-15T02:00:00Z'
.NOTES
    This is a staged engineering toolkit, not an unattended all-workloads migration.
    Manual workstreams remain documented for workloads lacking supported move APIs.
#>
[CmdletBinding()]
param(
    [ValidateSet('Menu','Plan','Prerequisites','AllReadOnly','InventorySource','InventoryTarget',
                 'ServicesSource','ServicesTarget','IdentityMap','Assess','DnsAudit',
                 'TargetUsers','Ctim','MailboxReadiness','MigrationPreview','MigrationCreate',
                 'MigrationValidate','MigrationStatus','MigrationStart')]
    [string]$Stage = 'Menu',
    [string]$ConfigPath = 'config/local.json',
    [string]$MappingCsv,
    [string]$CutoverUtc,
    [string]$JobId,
    [ValidateSet('Bootstrap','SourceCopy','TargetAccept','TargetMap','TargetWrite','TargetReport')]
    [string]$CtimPhase,
    [ValidateSet('Source','Target')][string]$TenantRole = 'Target',
    [guid]$SourceScopeSecurityGroupId,
    [guid]$RequestId,
    [string]$SourceSPOAdminUrl,
    [string]$TargetSPOAdminUrl,
    [switch]$IncludeServices,
    [switch]$SkipIntune,
    [switch]$SkipExchange,
    [switch]$SkipTeams,
    [switch]$SkipSharePoint,
    [switch]$Execute,
    [string]$ApprovalPhrase
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'modules/Migration.Workflow.psm1') -Force -ErrorAction Stop
$options = @{
    Stage=$Stage; RepoRoot=$PSScriptRoot; ConfigPath=$ConfigPath; MappingCsv=$MappingCsv
    CutoverUtc=$CutoverUtc; JobId=$JobId; CtimPhase=$CtimPhase; TenantRole=$TenantRole
    SourceScopeSecurityGroupId=$SourceScopeSecurityGroupId; RequestId=$RequestId
    SourceSPOAdminUrl=$SourceSPOAdminUrl; TargetSPOAdminUrl=$TargetSPOAdminUrl
    IncludeServices=[bool]$IncludeServices; SkipIntune=[bool]$SkipIntune
    SkipExchange=[bool]$SkipExchange; SkipTeams=[bool]$SkipTeams
    SkipSharePoint=[bool]$SkipSharePoint; Execute=[bool]$Execute; ApprovalPhrase=$ApprovalPhrase
}
if ($Stage -eq 'Menu') { Start-MigrationConsole -Options $options }
else { Invoke-MigrationStage -Options $options }
